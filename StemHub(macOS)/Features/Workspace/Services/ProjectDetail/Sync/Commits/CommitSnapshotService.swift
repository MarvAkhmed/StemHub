//
//  CommitSnapshotService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

struct PreparedLocalCommitSnapshot {
    let parentCommitID: String?
    let diff: ProjectDiff
    let fileSnapshot: [CommitFileSnapshot]
}

protocol LocalCommitSnapshotPreparing {
    nonisolated func prepareCommitSnapshot(projectID: String,
                                           localRootURL: URL,
                                           remoteSnapshot: [RemoteFileSnapshot],
                                           stagedFiles: [LocalFile]?,
                                           parentCommitID: String?
    ) async throws -> PreparedLocalCommitSnapshot

    nonisolated func scanWorkingFiles(localRootURL: URL) async throws -> [LocalFile]
}

struct DefaultLocalCommitSnapshotPreparer: LocalCommitSnapshotPreparing {
    nonisolated private let localFileSnapshotProvider: LocalFileSnapshotProviding
    nonisolated private let localCommitStore: LocalCommitStore

    init(
        localFileSnapshotProvider: LocalFileSnapshotProviding,
        localCommitStore: LocalCommitStore
    ) {
        self.localFileSnapshotProvider = localFileSnapshotProvider
        self.localCommitStore = localCommitStore
    }

    nonisolated func prepareCommitSnapshot(
        projectID: String,
        localRootURL: URL,
        remoteSnapshot: [RemoteFileSnapshot],
        stagedFiles: [LocalFile]?,
        parentCommitID: String?
    ) async throws -> PreparedLocalCommitSnapshot {
        let files = try await commitFiles(localRootURL: localRootURL, stagedFiles: stagedFiles)
        let previousSnapshot = try previousSnapshot(
            projectID: projectID,
            parentCommitID: parentCommitID,
            remoteSnapshot: remoteSnapshot
        )
        let snapshot = fileSnapshot(
            files: files,
            remoteSnapshot: remoteSnapshot,
            previousSnapshot: previousSnapshot
        )
        let resultingSnapshot = resultingFileSnapshot(
            stagedFiles: stagedFiles,
            previousSnapshot: previousSnapshot,
            snapshot: snapshot
        )

        return PreparedLocalCommitSnapshot(
            parentCommitID: parentCommitID,
            diff: diff(from: previousSnapshot, to: resultingSnapshot),
            fileSnapshot: resultingSnapshot
        )
    }

    nonisolated func scanWorkingFiles(localRootURL: URL) async throws -> [LocalFile] {
        try await localFileSnapshotProvider.scan(folderURL: localRootURL)
            .filter { !$0.isDirectory }
    }
}

private extension DefaultLocalCommitSnapshotPreparer {
    nonisolated func commitFiles(
        localRootURL: URL,
        stagedFiles: [LocalFile]?
    ) async throws -> [LocalFile] {
        guard let stagedFiles else {
            return try await scanWorkingFiles(localRootURL: localRootURL)
        }

        return stagedFiles.filter { !$0.isDirectory }
    }

    nonisolated func fileSnapshot(
        files: [LocalFile],
        remoteSnapshot: [RemoteFileSnapshot],
        previousSnapshot: [CommitFileSnapshot]
    ) -> [CommitFileSnapshot] {
        let remoteFilesByPath = Dictionary(remoteSnapshot.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let previousFilesByPath = Dictionary(previousSnapshot.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let previousFilesByHash = Dictionary(previousSnapshot.map { ($0.fileHash, $0) }, uniquingKeysWith: { $1 })

        return files.map { file in
            let previousFile = previousFilesByPath[file.path] ?? previousFilesByHash[file.fileHash]

            return CommitFileSnapshot(
                fileID: previousFile?.fileID ?? remoteFilesByPath[file.path]?.fileID ?? file.fileHash,
                path: file.path,
                blobID: file.fileHash,
                hash: file.fileHash,
                versionNumber: versionNumber(for: file, previousFile: previousFile)
            )
        }
    }

    nonisolated func resultingFileSnapshot(
        stagedFiles: [LocalFile]?,
        previousSnapshot: [CommitFileSnapshot],
        snapshot: [CommitFileSnapshot]
    ) -> [CommitFileSnapshot] {
        guard stagedFiles != nil else { return snapshot }

        var resultByPath = Dictionary(previousSnapshot.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        for fileSnapshot in snapshot {
            resultByPath[fileSnapshot.path] = fileSnapshot
        }

        return resultByPath.values.sorted { $0.path < $1.path }
    }

    nonisolated func diff(
        from old: [CommitFileSnapshot],
        to new: [CommitFileSnapshot]
    ) -> ProjectDiff {
        let oldByPath = Dictionary(old.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let newByPath = Dictionary(new.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let addedCandidates = new
            .filter { oldByPath[$0.path] == nil }
            .sorted { $0.path < $1.path }
        let removedCandidates = old
            .filter { newByPath[$0.path] == nil }
            .sorted { $0.path < $1.path }

        var entries: [FileDiff] = []
        var renamedNewPaths = Set<String>()
        var renamedOldPaths = Set<String>()

        for added in addedCandidates {
            guard let removed = removedCandidates.first(where: {
                !renamedOldPaths.contains($0.path) &&
                ($0.fileID == added.fileID || $0.fileHash == added.fileHash)
            }) else {
                continue
            }

            entries.append(FileDiff(
                path: added.path,
                changeType: .renamed,
                oldPath: removed.path,
                oldHash: removed.fileHash,
                newHash: added.fileHash
            ))
            renamedNewPaths.insert(added.path)
            renamedOldPaths.insert(removed.path)
        }

        entries += addedCandidates
            .filter { !renamedNewPaths.contains($0.path) }
            .map {
                FileDiff(
                    path: $0.path,
                    changeType: .added,
                    oldPath: nil,
                    oldHash: nil,
                    newHash: $0.fileHash
                )
            }

        entries += removedCandidates
            .filter { !renamedOldPaths.contains($0.path) }
            .map {
                FileDiff(
                    path: $0.path,
                    changeType: .removed,
                    oldPath: nil,
                    oldHash: $0.fileHash,
                    newHash: nil
                )
            }

        entries += new
            .compactMap { file -> FileDiff? in
                guard let previousFile = oldByPath[file.path],
                      previousFile.fileHash != file.fileHash else {
                    return nil
                }

                return FileDiff(
                    path: file.path,
                    changeType: .modified,
                    oldPath: nil,
                    oldHash: previousFile.fileHash,
                    newHash: file.fileHash
                )
            }

        return ProjectDiff(files: entries.sorted { lhs, rhs in
            if lhs.path == rhs.path {
                return (lhs.oldPath ?? "") < (rhs.oldPath ?? "")
            }
            return lhs.path < rhs.path
        })
    }

    nonisolated func previousSnapshot(
        projectID: String,
        parentCommitID: String?,
        remoteSnapshot: [RemoteFileSnapshot]
    ) throws -> [CommitFileSnapshot] {
        guard let parentCommitID else {
            return remoteSnapshot.map {
                CommitFileSnapshot(
                    fileID: $0.fileID,
                    path: $0.path,
                    blobID: $0.fileHash,
                    hash: $0.fileHash,
                    versionNumber: $0.versionNumber
                )
            }
        }

        let localCommits = try localCommitStore.loadLocalCommits(projectID: projectID)
        guard let parentCommit = localCommits.first(where: { $0.id == parentCommitID }) else {
            throw SyncError.parentCommitNotFound
        }

        return parentCommit.commit.fileSnapshot
    }

    nonisolated func versionNumber(
        for file: LocalFile,
        previousFile: CommitFileSnapshot?
    ) -> Int {
        guard let previousFile else { return 1 }
        return previousFile.fileHash == file.fileHash
            ? previousFile.versionNumber
            : previousFile.versionNumber + 1
    }
}
