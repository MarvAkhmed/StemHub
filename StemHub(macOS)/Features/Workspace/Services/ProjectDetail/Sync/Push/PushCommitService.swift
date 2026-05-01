//
//  PushCommitService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

protocol CommitPushing: Sendable {
    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion
}

final class PushCommitService: CommitPushing, @unchecked Sendable {
    private let versionRepository: RemoteVersionRepository
    private let commitRepository: RemoteCommitPersisting
    private let fileTransferStrategy: RemoteFileTransfering
    private let uploadQueue: UploadQueueActor<String>
    private let fileManager: FileManager

    init(
        versionRepository: RemoteVersionRepository,
        commitRepository: RemoteCommitPersisting,
        fileTransferStrategy: RemoteFileTransfering,
        uploadQueue: UploadQueueActor<String> = UploadQueueActor(),
        fileManager: FileManager = .default
    ) {
        self.versionRepository = versionRepository
        self.commitRepository = commitRepository
        self.fileTransferStrategy = fileTransferStrategy
        self.uploadQueue = uploadQueue
        self.fileManager = fileManager
    }

    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        let preparedPush = try await preparePush(commit, localRootURL: localRootURL)
        return try await commitRepository.persistCommitPush(preparedPush, branchID: branchID)
    }
}

private struct PreparedFileVersion {
    let fileVersion: FileVersion
    let blob: FileBlob
}

private extension PushCommitService {
    func preparePush(_ commit: Commit, localRootURL: URL) async throws -> PreparedCommitPush {
        let parentVersionID = expectedParentVersionID(for: commit)
        let versionNumber = try await nextVersionNumber(after: parentVersionID)
        let parentFileVersions = try await fileVersions(versionID: parentVersionID)
        var resultingFileVersionsByPath = Dictionary(
            parentFileVersions.map { ($0.path, $0) },
            uniquingKeysWith: { $1 }
        )
        var fileVersionsToSave: [FileVersion] = []
        var blobsToSaveByID: [String: FileBlob] = [:]
        let commitSnapshotsByPath = Dictionary(
            commit.fileSnapshot.map { ($0.path, $0) },
            uniquingKeysWith: { $1 }
        )

        for diff in commit.diff.files {
            switch diff.changeType {
            case .added, .modified:
                let preparedFileVersion = try await uploadFileVersion(
                    snapshotForDiff(diff, in: commitSnapshotsByPath),
                    projectID: commit.projectID,
                    localRootURL: localRootURL
                )
                resultingFileVersionsByPath[diff.path] = preparedFileVersion.fileVersion
                fileVersionsToSave.append(preparedFileVersion.fileVersion)
                blobsToSaveByID[preparedFileVersion.blob.id] = preparedFileVersion.blob

            case .removed:
                resultingFileVersionsByPath.removeValue(forKey: diff.path)

            case .renamed:
                if let oldPath = diff.oldPath {
                    resultingFileVersionsByPath.removeValue(forKey: oldPath)
                }

                let preparedFileVersion = try await uploadFileVersion(
                    snapshotForDiff(diff, in: commitSnapshotsByPath),
                    projectID: commit.projectID,
                    localRootURL: localRootURL
                )
                resultingFileVersionsByPath[diff.path] = preparedFileVersion.fileVersion
                fileVersionsToSave.append(preparedFileVersion.fileVersion)
                blobsToSaveByID[preparedFileVersion.blob.id] = preparedFileVersion.blob
            }
        }

        let projectVersion = ProjectVersion(
            id: UUID().uuidString,
            projectID: commit.projectID,
            versionNumber: versionNumber,
            parentVersionID: parentVersionID,
            fileVersionIDs: resultingFileVersionsByPath.values
                .sorted { $0.path < $1.path }
                .map(\.id),
            createdBy: commit.createdBy,
            createdAt: Date(),
            notes: commit.message,
            diff: commit.diff,
            commitId: commit.id
        )

        return PreparedCommitPush(
            commit: commit,
            expectedParentVersionID: parentVersionID,
            projectVersion: projectVersion,
            fileVersionsToSave: fileVersionsToSave,
            blobsToSave: Array(blobsToSaveByID.values)
        )
    }

    func snapshotForDiff(
        _ diff: FileDiff,
        in snapshotsByPath: [String: CommitFileSnapshot]
    ) throws -> CommitFileSnapshot {
        guard let fileSnapshot = snapshotsByPath[diff.path] else {
            throw CocoaError(.fileNoSuchFile)
        }

        return fileSnapshot
    }

    func uploadFileVersion(
        _ fileSnapshot: CommitFileSnapshot,
        projectID: String,
        localRootURL: URL
    ) async throws -> PreparedFileVersion {
        let fileURL = localRootURL.appendingPathComponent(fileSnapshot.path)
        let storagePath = "projects/\(projectID)/blobs/\(fileSnapshot.fileHash)"

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw CocoaError(.fileNoSuchFile)
        }

        _ = try await uploadQueue.upload(blobID: fileSnapshot.fileHash) {
            let fileTransferStrategy = self.fileTransferStrategy
            return Task {
                try await fileTransferStrategy.uploadFile(localURL: fileURL, storagePath: storagePath)
            }
        }

        let blob = FileBlob(
            id: fileSnapshot.fileHash,
            storagePath: storagePath,
            size: fileSize(at: fileURL),
            hash: fileSnapshot.fileHash,
            createdAt: .now
        )

        let fileVersion = FileVersion(
            id: UUID().uuidString,
            fileID: fileSnapshot.fileID,
            blobID: fileSnapshot.fileHash,
            path: fileSnapshot.path,
            versionNumber: fileSnapshot.versionNumber,
            syncStatus: .synced,
            createdAt: Date()
        )

        return PreparedFileVersion(fileVersion: fileVersion, blob: blob)
    }

    func fileSize(at url: URL) -> Int64 {
        guard let size = try? fileManager.attributesOfItem(atPath: url.path)[.size] as? NSNumber else {
            return 0
        }

        return size.int64Value
    }

    func expectedParentVersionID(for commit: Commit) -> String? {
        commit.basedOnVersionID.isEmpty ? nil : commit.basedOnVersionID
    }

    func fileVersions(versionID: String?) async throws -> [FileVersion] {
        guard let versionID else { return [] }

        guard let version = try await versionRepository.fetchVersion(versionID: versionID) else {
            throw SyncError.projectNotFound
        }

        return try await versionRepository.fetchFileVersions(fileVersionIDs: version.fileVersionIDs)
    }

    func nextVersionNumber(after parentVersionID: String?) async throws -> Int {
        guard let parentVersionID else { return 1 }

        guard let parentVersion = try await versionRepository.fetchVersion(versionID: parentVersionID) else {
            throw SyncError.projectNotFound
        }

        return parentVersion.versionNumber + 1
    }
}
