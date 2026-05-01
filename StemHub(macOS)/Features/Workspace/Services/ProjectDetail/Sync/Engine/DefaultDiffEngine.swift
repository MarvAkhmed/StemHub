//
//  DefaultDiffEngine.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol DiffEngineStrategy: Sendable {
    nonisolated func computeDiff(local: [LocalFile], remote: [RemoteFileSnapshot]) -> DiffResult
    nonisolated func mapToProjectDiff(_ diff: DiffResult) -> ProjectDiff
}

struct DefaultDiffEngineStrategy: DiffEngineStrategy {
    nonisolated func computeDiff(local: [LocalFile], remote: [RemoteFileSnapshot]) -> DiffResult {
        let localMap = Dictionary(local.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let remoteMap = Dictionary(remote.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let localHashMap = Dictionary(local.map { ($0.fileHash, $0) }, uniquingKeysWith: { $1 })
        let remoteHashMap = Dictionary(remote.map { ($0.fileHash, $0) }, uniquingKeysWith: { $1 })

        var added: [LocalFile] = []
        var removed: [RemoteFileSnapshot] = []
        var modified: [(LocalFile, RemoteFileSnapshot)] = []
        var renamed: [(LocalFile, RemoteFileSnapshot)] = []

        for (path, localFile) in localMap {
            if let remoteFile = remoteMap[path] {
                if localFile.fileHash != remoteFile.fileHash {
                    modified.append((localFile, remoteFile))
                }
            } else {
                added.append(localFile)
            }
        }

        for (path, remoteFile) in remoteMap where localMap[path] == nil {
            removed.append(remoteFile)
        }

        var realAdded: [LocalFile] = []
        var realRemoved: [RemoteFileSnapshot] = []

        for localFile in added {
            if let oldFile = remoteHashMap[localFile.fileHash] {
                renamed.append((localFile, oldFile))
            } else {
                realAdded.append(localFile)
            }
        }

        for remoteFile in removed {
            if localHashMap[remoteFile.fileHash] == nil {
                realRemoved.append(remoteFile)
            }
        }

        return DiffResult(
            added: realAdded,
            removed: realRemoved,
            modified: modified + renamed.map { ($0.0, $0.1) }
        )
    }

    nonisolated func mapToProjectDiff(_ diff: DiffResult) -> ProjectDiff {
        var files: [FileDiff] = []

        files += diff.added.map {
            FileDiff(path: $0.path, changeType: .added, oldPath: nil, oldHash: nil, newHash: $0.fileHash)
        }

        files += diff.removed.map {
            FileDiff(path: $0.path, changeType: .removed, oldPath: nil, oldHash: $0.fileHash, newHash: nil)
        }

        files += diff.modified.map {
            FileDiff(
                path: $0.local.path,
                changeType: $0.local.path != $0.remote.path ? .renamed : .modified,
                oldPath: $0.local.path != $0.remote.path ? $0.remote.path : nil,
                oldHash: $0.remote.fileHash,
                newHash: $0.local.fileHash
            )
        }

        return ProjectDiff(files: files)
    }
}
