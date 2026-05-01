//
//  SyncOrchestrator.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation


final class SyncOrchestrator {
    private let localCommitSnapshotPreparer: LocalCommitSnapshotPreparing
    private let commitPusher: CommitPushing
    private let branchRepository: BranchRepository
    private let versionRepository: VersionRepository
    private let blobRepository: BlobRepository
    private let workingTree: WorkingTreeCheckingOut

    init(
        localCommitSnapshotPreparer: LocalCommitSnapshotPreparing,
        commitPusher: CommitPushing,
        branchRepository: BranchRepository,
        versionRepository: VersionRepository,
        blobRepository: BlobRepository,
        workingTree: WorkingTreeCheckingOut
    ) {
        self.localCommitSnapshotPreparer = localCommitSnapshotPreparer
        self.commitPusher = commitPusher
        self.branchRepository = branchRepository
        self.versionRepository = versionRepository
        self.blobRepository = blobRepository
        self.workingTree = workingTree
    }

    func commit(
        localPath: URL,
        localState: ProjectSyncState,
        remoteSnapshot: [RemoteFileSnapshot],
        userID: String,
        message: String?,
        stagedFiles: [LocalFile]? = nil,
        parentCommitID: String?
    ) async throws -> Commit {
        let preparedSnapshot = try await localCommitSnapshotPreparer.prepareCommitSnapshot(
            projectID: localState.projectID,
            localRootURL: localPath,
            remoteSnapshot: remoteSnapshot,
            stagedFiles: stagedFiles,
            parentCommitID: parentCommitID
        )

        return Commit(
            id: UUID().uuidString,
            projectID: localState.projectID,
            parentCommitID: preparedSnapshot.parentCommitID,
            basedOnVersionID: localState.lastPulledVersionID ?? "",
            diff: preparedSnapshot.diff,
            fileSnapshot: preparedSnapshot.fileSnapshot,
            createdBy: userID,
            createdAt: Date(),
            message: message ?? "Auto commit",
            status: .local
        )
    }

    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        try await commitPusher.pushCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }

    func hasLocalChanges(
        localRootURL: URL,
        remoteSnapshot: [RemoteFileSnapshot]
    ) async throws -> Bool {
        try await workingTree.hasLocalChanges(
            localRootURL: localRootURL,
            remoteSnapshot: remoteSnapshot
        )
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
            if updatedState.lastPulledVersionID != nil {
                try await workingTree.checkout([], at: localRootURL)
                updatedState.lastPulledVersionID = nil
            }
            return updatedState
        }

        if updatedState.lastPulledVersionID == latestVersionID {
            return updatedState
        }

        try await checkout(versionID: latestVersionID, to: localRootURL)
        updatedState.lastPulledVersionID = latestVersionID
        return updatedState
    }
}

private extension SyncOrchestrator {
    func checkout(versionID: String, to localRootURL: URL) async throws {
        guard let version = try await versionRepository.fetchVersion(versionID: versionID) else {
            throw SyncError.projectNotFound
        }

        let fileVersions = try await versionRepository.fetchFileVersions(
            fileVersionIDs: version.fileVersionIDs
        )
        var checkoutFiles: [WorkingTreeCheckoutFile] = []
        for fileVersion in fileVersions {
            guard let blob = try await blobRepository.fetchBlob(blobID: fileVersion.blobID) else {
                throw SyncError.projectNotFound
            }

            checkoutFiles.append(WorkingTreeCheckoutFile(
                path: fileVersion.path,
                blobID: fileVersion.blobID,
                storagePath: blob.storagePath
            ))
        }

        try await workingTree.checkout(checkoutFiles, at: localRootURL)
    }
}
