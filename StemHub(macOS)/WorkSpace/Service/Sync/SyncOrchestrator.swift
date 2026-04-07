//
//  SyncOrchestrator.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

enum SyncError: Error {
    case branchNotFound, projectNotFound, outdatedCommit
}

final class SyncOrchestrator {
    private let scanStrategy: FileScanStrategy
    private let diffStrategy: DiffEngineStrategy
    private let commitStorage: CommitStorageStrategy
    private let remoteFetch: RemoteFetchStrategy
    private let fileUploadStrategy: FileUploadStrategy
    private let branchStrategy: FirestoreBranchStrategy
    private let versionStrategy: FirestoreVersionStrategy
    private let blobStrategy: FirestoreBlobStrategy

    init(
        scanStrategy: FileScanStrategy = LocalFileScanner(),
        diffStrategy: DiffEngineStrategy = DefaultDiffEngineStrategy(),
        commitStorage: CommitStorageStrategy = DefaultCommitStorageStrategy(),
        remoteFetch: RemoteFetchStrategy = FirestoreRemoteFetch(),
        fileUploadStrategy: FileUploadStrategy = FileUploadService(),
        branchStrategy: FirestoreBranchStrategy = DefaultFirestoreBranchStrategy(),
        versionStrategy: FirestoreVersionStrategy = DefaultFirestoreVersionStrategy(),
        blobStrategy: FirestoreBlobStrategy = DefaultFirestoreBlobStrategy()
    ) {
        self.scanStrategy = scanStrategy
        self.diffStrategy = diffStrategy
        self.commitStorage = commitStorage
        self.remoteFetch = remoteFetch
        self.fileUploadStrategy = fileUploadStrategy
        self.branchStrategy = branchStrategy
        self.versionStrategy = versionStrategy
        self.blobStrategy = blobStrategy
    }

    func commit(localPath: URL,
                localState: LocalProjectState,
                remoteSnapshot: [RemoteFileSnapshot],
                userID: String,
                message: String?,
                stagedFiles: [LocalFile]? = nil) async throws -> Commit {
        
        let localFiles =  try scanStrategy.scan(folderURL: localPath)
        let stagedFiles = stagedFiles ?? localFiles
        
        let diffResult = diffStrategy.computeDiff(local: stagedFiles, remote: remoteSnapshot)
        let projectDiff = diffStrategy.mapToProjectDiff(diffResult)

        let snapshot: [CommitFileSnapshot] = stagedFiles
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

        let commit = Commit(
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

        return commit
    }

    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        return try await commitStorage.saveCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }

    func pullProject(
        projectID: String,
        branchID: String,
        localRootURL: URL,
        state: LocalProjectState
    ) async throws -> LocalProjectState {
        var updatedState = state

        // 1. Fetch branch using injected strategy
        guard let branch = try await branchStrategy.fetchBranch(branchID: branchID) else {
            throw SyncError.branchNotFound
        }

        guard let latestVersionID = branch.headVersionID else {
            return updatedState
        }

        if updatedState.lastPulledVersionID == latestVersionID {
            return updatedState
        }

        // 2. Fetch project version
        guard let projectVersion = try await versionStrategy.fetchVersion(versionID: latestVersionID) else {
            throw SyncError.projectNotFound
        }

        // 3. Fetch all file versions for this project version
        let fileVersions = try await versionStrategy.fetchFileVersions(fileVersionIDs: projectVersion.fileVersionIDs)

        // 4. Fetch blobs for each file version
        var blobs: [String: FileBlob] = [:]
        for fileVersion in fileVersions {
            if let blob = try await blobStrategy.fetchBlob(blobID: fileVersion.blobID) {
                blobs[fileVersion.blobID] = blob
            }
        }

        // 5. Apply diffs to local folder
        for diff in projectVersion.diff.files {
            let filePath = localRootURL.appendingPathComponent(diff.path)

            switch diff.changeType {
            case .added, .modified:
                guard let newHash = diff.newHash, let blob = blobs[newHash] else { continue }
                let dir = filePath.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                try? FileManager.default.removeItem(at: filePath)
                try await fileUploadStrategy.downloadFile(storagePath: blob.storagePath, to: filePath)

            case .removed:
                if FileManager.default.fileExists(atPath: filePath.path) {
                    try FileManager.default.removeItem(at: filePath)
                }

            case .renamed:
                guard let oldPath = diff.oldPath else { continue }
                let oldURL = localRootURL.appendingPathComponent(oldPath)
                if FileManager.default.fileExists(atPath: oldURL.path) {
                    let dir = filePath.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    try FileManager.default.moveItem(at: oldURL, to: filePath)
                }
            }
        }

        updatedState.lastPulledVersionID = latestVersionID
        return updatedState
    }
}
