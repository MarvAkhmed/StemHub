//
//  SyncOrchestrator.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation


final class SyncOrchestrator {
    private let scanStrategy: FileScanner
    private let diffStrategy: DiffEngineStrategy
    private let commitRepository: CommitRepository
    private let fileUploadStrategy: FileUploadStrategy
    private let branchRepository: BranchRepository
    private let versionRepository: VersionRepository
    private let blobRepository: BlobRepository

    init(
        scanStrategy: FileScanner = LocalFileScanner(),
        diffStrategy: DiffEngineStrategy = DefaultDiffEngineStrategy(),
        commitRepository: CommitRepository = DefaultCommitRepository(),
        fileUploadStrategy: FileUploadStrategy = FileUploadService(),
        branchRepository: BranchRepository = DefaultBranchRepository(),
        versionRepository: VersionRepository = DefaultVersionRepository(),
        blobRepository: BlobRepository = DefaultBlobRepository()
    ) {
        self.scanStrategy = scanStrategy
        self.diffStrategy = diffStrategy
        self.commitRepository = commitRepository
        self.fileUploadStrategy = fileUploadStrategy
        self.branchRepository = branchRepository
        self.versionRepository = versionRepository
        self.blobRepository = blobRepository
    }

    func commit(
        localPath: URL,
        localState: ProjectSyncState,
        remoteSnapshot: [RemoteFileSnapshot],
        userID: String,
        message: String?,
        stagedFiles: [LocalFile]? = nil
    ) async throws -> Commit {
        let files = try stagedFiles ?? scanStrategy.scan(folderURL: localPath)
        let diffResult = diffStrategy.computeDiff(local: files, remote: remoteSnapshot)
        let projectDiff = diffStrategy.mapToProjectDiff(diffResult)

        let snapshot = files
            .filter { !$0.isDirectory }
            .map {
                CommitFileSnapshot(
                    fileID: UUID().uuidString,
                    path: $0.path,
                    blobID: "",
                    hash: $0.hash,
                    versionNumber: 1
                )
            }

        return Commit(
            id: UUID().uuidString,
            projectID: localState.projectID,
            parentCommitID: localState.lastCommittedID,
            basedOnVersionID: localState.lastPulledVersionID ?? "",
            diff: projectDiff,
            fileSnapshot: snapshot,
            createdBy: userID,
            createdAt: Date(),
            message: message ?? "Auto commit",
            status: .local
        )
    }

    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        try await commitRepository.pushCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }

    func pullProject(
        projectID: String,
        branchID: String,
        localRootURL: URL,
        state: ProjectSyncState
    ) async throws -> ProjectSyncState {
        var updatedState = state

        guard let branch = try await branchRepository.fetchBranch(branchID: branchID) else {
            throw SyncError.branchNotFound
        }

        guard let latestVersionID = branch.headVersionID else {
            return updatedState
        }

        if updatedState.lastPulledVersionID == latestVersionID {
            return updatedState
        }

        guard let projectVersion = try await versionRepository.fetchVersion(versionID: latestVersionID) else {
            throw SyncError.projectNotFound
        }

        let fileVersions = try await versionRepository.fetchFileVersions(fileVersionIDs: projectVersion.fileVersionIDs)

        var blobs: [String: FileBlob] = [:]
        for fileVersion in fileVersions {
            if let blob = try await blobRepository.fetchBlob(blobID: fileVersion.blobID) {
                blobs[fileVersion.blobID] = blob
            }
        }

        for diff in projectVersion.diff.files {
            let targetURL = localRootURL.appendingPathComponent(diff.path)

            switch diff.changeType {
            case .added, .modified:
                guard let newHash = diff.newHash, let blob = blobs[newHash] else { continue }
                try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? FileManager.default.removeItem(at: targetURL)
                try await fileUploadStrategy.downloadFile(storagePath: blob.storagePath, to: targetURL)

            case .removed:
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }

            case .renamed:
                guard let oldPath = diff.oldPath else { continue }
                let sourceURL = localRootURL.appendingPathComponent(oldPath)
                if FileManager.default.fileExists(atPath: sourceURL.path) {
                    try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try FileManager.default.moveItem(at: sourceURL, to: targetURL)
                }
            }
        }

        updatedState.lastPulledVersionID = latestVersionID
        return updatedState
    }
}

