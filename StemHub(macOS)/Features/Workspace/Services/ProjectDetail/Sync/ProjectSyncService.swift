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
    func createCommit(projectID: String,
                      branchID: String,
                      stagedFiles: [LocalFile],
                      userID: String,
                      message: String,
                      parentCommitID: String?) async throws -> Commit
    func pushCommit(_ localCommit: LocalCommit, branchID: String) async throws -> ProjectVersion
    func pushCommitResolvingOutdatedHead(_ localCommit: LocalCommit, branchID: String) async throws -> ProjectVersion
    func rebaseCommit(_ localCommit: LocalCommit, onto newBaseVersionID: String) async throws -> LocalCommit
}

final class DefaultProjectSyncService: ProjectSyncService {
    private let syncOrchestrator: SyncOrchestrator
    private let branchRepository: BranchRepository
    private let remoteSnapshotRepository: RemoteSnapshotRepository
    private let stateStore: ProjectStateStore

    init(
        syncOrchestrator: SyncOrchestrator,
        branchRepository: BranchRepository,
        remoteSnapshotRepository: RemoteSnapshotRepository,
        stateStore: ProjectStateStore
    ) {
        self.syncOrchestrator = syncOrchestrator
        self.branchRepository = branchRepository
        self.remoteSnapshotRepository = remoteSnapshotRepository
        self.stateStore = stateStore
    }

    func pull(projectID: String, branchID: String) async throws -> ProjectSyncState {
        let state = stateStore.syncState(for: projectID)
        guard !state.localPath.isEmpty else { throw ProjectSyncServiceError.missingLocalPath }

        let localRootURL = URL(fileURLWithPath: state.localPath)
        try await ensurePullCanWriteLocalWorkspace(
            localRootURL: localRootURL,
            branchID: branchID,
            state: state
        )

        let updatedState = try await syncOrchestrator.pullProject(
            projectID: projectID,
            branchID: branchID,
            localRootURL: localRootURL,
            state: state
        )

        var checkedOutState = updatedState
        checkedOutState.currentBranchID = branchID
        stateStore.saveSyncState(checkedOutState)
        return checkedOutState
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
        message: String,
        parentCommitID: String?
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
            stagedFiles: stagedFiles.isEmpty ? nil : stagedFiles,
            parentCommitID: parentCommitID
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

    func pushCommitResolvingOutdatedHead(_ localCommit: LocalCommit, branchID: String) async throws -> ProjectVersion {
        do {
            return try await pushCommit(localCommit, branchID: branchID)
        } catch SyncError.outdatedCommit {
            guard let remoteHeadVersionID = try await branchRepository.fetchHeadVersionID(branchID: branchID) else {
                throw ProjectBranchError.missingSourceVersion
            }

            let rebasedCommit = try await rebaseCommit(localCommit, onto: remoteHeadVersionID)
            return try await pushCommit(rebasedCommit, branchID: branchID)
        }
    }

    func rebaseCommit(_ localCommit: LocalCommit, onto newBaseVersionID: String) async throws -> LocalCommit {
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
            diff: localCommit.commit.diff,
            fileSnapshot: localCommit.commit.fileSnapshot,
            createdBy: localCommit.commit.createdBy,
            createdAt: Date(),
            message: localCommit.commit.message,
            status: .local
        )

        return LocalCommit(
            id: newCommitID,
            parentCommitID: localCommit.parentCommitID,
            commit: rebasedCommit,
            cachedFolderURL: newCacheFolder,
            isPushed: false,
            createdAt: Date()
        )
    }
}

private extension DefaultProjectSyncService {
    func ensurePullCanWriteLocalWorkspace(
        localRootURL: URL,
        branchID: String,
        state: ProjectSyncState
    ) async throws {
        let remoteHeadVersionID = try await branchRepository.fetchHeadVersionID(branchID: branchID)
        guard remoteHeadVersionID != state.lastPulledVersionID else {
            return
        }

        let baseSnapshot = try await remoteSnapshotRepository.fetchRemoteSnapshot(
            versionID: state.lastPulledVersionID ?? ""
        )
        let hasLocalChanges = try await syncOrchestrator.hasLocalChanges(
            localRootURL: localRootURL,
            remoteSnapshot: baseSnapshot
        )

        if hasLocalChanges {
            throw ProjectSyncServiceError.localWorkspaceHasUncommittedChanges
        }
    }
}
