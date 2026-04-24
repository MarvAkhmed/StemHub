//
//  ProjectSyncService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectSyncService {
    func pull(projectID: String, branchID: String) async throws -> ProjectSyncState
    func ensureRemoteHeadIsCurrent(projectID: String, branchID: String) async throws
    func createCommit(projectID: String, branchID: String, stagedFiles: [LocalFile], userID: String, message: String) async throws -> Commit
    func pushCommit(_ localCommit: LocalCommit, branchID: String) async throws -> ProjectVersion
    func rebaseCommit(_ localCommit: LocalCommit, onto newBaseVersionID: String) async throws -> LocalCommit
}

final class DefaultProjectSyncService: ProjectSyncService {
    private let syncOrchestrator: SyncOrchestrator
    private let branchRepository: BranchRepository
    private let remoteSnapshotRepository: RemoteSnapshotRepository
    private let stateStore: ProjectStateStore
    private let diffEngine: DiffEngineStrategy

    init(
        syncOrchestrator: SyncOrchestrator,
        branchRepository: BranchRepository,
        remoteSnapshotRepository: RemoteSnapshotRepository,
        stateStore: ProjectStateStore,
        diffEngine: DiffEngineStrategy
    ) {
        self.syncOrchestrator = syncOrchestrator
        self.branchRepository = branchRepository
        self.remoteSnapshotRepository = remoteSnapshotRepository
        self.stateStore = stateStore
        self.diffEngine = diffEngine
    }

    func pull(projectID: String, branchID: String) async throws -> ProjectSyncState {
        var state = stateStore.syncState(for: projectID)
        guard !state.localPath.isEmpty else { throw ProjectSyncServiceError.missingLocalPath }

        state.currentBranchID = branchID

        let updatedState = try await syncOrchestrator.pullProject(
            projectID: projectID,
            branchID: branchID,
            localRootURL: URL(fileURLWithPath: state.localPath),
            state: state
        )

        stateStore.saveSyncState(updatedState)
        return updatedState
    }

    func ensureRemoteHeadIsCurrent(projectID: String, branchID: String) async throws {
        let state = stateStore.syncState(for: projectID)
        let remoteHead = try await branchRepository.fetchHeadVersionID(branchID: branchID)
        let localBase = state.lastPulledVersionID ?? ""

        if let remoteHead, remoteHead != localBase {
            throw ProjectSyncServiceError.remoteHasNewCommits
        }
    }

    func createCommit(
        projectID: String,
        branchID: String,
        stagedFiles: [LocalFile],
        userID: String,
        message: String
    ) async throws -> Commit {
        var state = stateStore.syncState(for: projectID)
        guard !state.localPath.isEmpty else { throw ProjectSyncServiceError.missingLocalPath }

        state.currentBranchID = branchID

        let remoteSnapshot = try await remoteSnapshotRepository.fetchRemoteSnapshot(
            versionID: state.lastPulledVersionID ?? ""
        )

        return try await syncOrchestrator.commit(
            localPath: URL(fileURLWithPath: state.localPath),
            localState: state,
            remoteSnapshot: remoteSnapshot,
            userID: userID,
            message: message,
            stagedFiles: stagedFiles.isEmpty ? nil : stagedFiles
        )
    }

    func pushCommit(_ localCommit: LocalCommit, branchID: String) async throws -> ProjectVersion {
        let newVersion = try await syncOrchestrator.pushCommit(
            localCommit.commit,
            localRootURL: localCommit.cachedFolderURL,
            branchID: branchID
        )

        var state = stateStore.syncState(for: localCommit.commit.projectID)
        state.lastPulledVersionID = newVersion.id
        state.lastCommittedID = localCommit.commit.id
        state.currentBranchID = branchID
        stateStore.saveSyncState(state)

        return newVersion
    }

    func rebaseCommit(_ localCommit: LocalCommit, onto newBaseVersionID: String) async throws -> LocalCommit {
        let remoteSnapshot = try await remoteSnapshotRepository.fetchRemoteSnapshot(versionID: newBaseVersionID)

        let localFiles: [LocalFile] = localCommit.commit.fileSnapshot.compactMap { snapshot in
            let fileURL = localCommit.cachedFolderURL.appendingPathComponent(snapshot.path)
            let hash = LocalFileScanner.hashFile(at: fileURL)
            let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0

            return LocalFile(
                path: snapshot.path,
                name: (snapshot.path as NSString).lastPathComponent,
                fileExtension: (snapshot.path as NSString).pathExtension,
                size: size,
                hash: hash,
                isDirectory: false
            )
        }

        let rebasedDiff = diffEngine.mapToProjectDiff(
            diffEngine.computeDiff(local: localFiles, remote: remoteSnapshot)
        )

        let newCommitID = UUID().uuidString
        let newCacheFolder = localCommit.cachedFolderURL
            .deletingLastPathComponent()
            .appendingPathComponent(newCommitID, isDirectory: true)

        try FileManager.default.createDirectory(at: newCacheFolder, withIntermediateDirectories: true)

        for snapshot in localCommit.commit.fileSnapshot {
            let source = localCommit.cachedFolderURL.appendingPathComponent(snapshot.path)
            let destination = newCacheFolder.appendingPathComponent(snapshot.path)
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: destination)
        }

        let rebasedCommit = Commit(
            id: newCommitID,
            projectID: localCommit.commit.projectID,
            parentCommitID: localCommit.commit.parentCommitID,
            basedOnVersionID: newBaseVersionID,
            diff: rebasedDiff,
            fileSnapshot: localCommit.commit.fileSnapshot,
            createdBy: localCommit.commit.createdBy,
            createdAt: Date(),
            message: localCommit.commit.message,
            status: .local
        )

        try? FileManager.default.removeItem(at: localCommit.cachedFolderURL)

        return LocalCommit(
            id: newCommitID,
            commit: rebasedCommit,
            cachedFolderURL: newCacheFolder,
            isPushed: false,
            createdAt: Date()
        )
    }
}
