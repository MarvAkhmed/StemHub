//
//  StandardDiffEngine.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

struct StandardDiffEngine: DiffCalculationStrategy {
    func computeDiff(local: [LocalFile], remote: [RemoteFileSnapshot]) -> DiffResult {
        let localMap = Dictionary(local.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let remoteMap = Dictionary(remote.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let localHashMap = Dictionary(local.map { ($0.hash, $0) }, uniquingKeysWith: { $1 })
        let remoteHashMap = Dictionary(remote.map { ($0.hash, $0) }, uniquingKeysWith: { $1 })
        
        var added: [LocalFile] = []
        var removed: [RemoteFileSnapshot] = []
        var modified: [(LocalFile, RemoteFileSnapshot)] = []
        var renamed: [(LocalFile, RemoteFileSnapshot)] = []
        
        for (path, localFile) in localMap {
            if let remoteFile = remoteMap[path] {
                if localFile.hash != remoteFile.hash {
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
            if let oldFile = remoteHashMap[localFile.hash] {
                renamed.append((localFile, RemoteFileSnapshot(
                    fileID: oldFile.fileID,
                    path: oldFile.path,
                    hash: oldFile.hash,
                    versionID: ""
                )))
            } else {
                realAdded.append(localFile)
            }
        }
        
        for remoteFile in removed {
            if let _ = localHashMap[remoteFile.hash] {
                print("file renamed from \(remoteFile.path)")
            } else {
                realRemoved.append(remoteFile)
            }
        }
        
        return DiffResult(added: realAdded, removed: realRemoved, modified: modified + renamed.map { ($0.0, $0.1) })
    }
    
    func mapToProjectDiff(_ diff: DiffResult) -> ProjectDiff {
        var files: [FileDiff] = []
        
        files += diff.added.map {
            FileDiff(path: $0.path, changeType: .added, oldPath: nil, oldHash: nil, newHash: $0.hash)
        }
        files += diff.removed.map {
            FileDiff(path: $0.path, changeType: .removed, oldPath: nil, oldHash: $0.hash, newHash: nil)
        }
        files += diff.modified.map {
            FileDiff(path: $0.local.path,
                     changeType: $0.local.path != $0.1.path ? .renamed : .modified,
                     oldPath: $0.local.path != $0.1.path ? $0.1.path : nil,
                     oldHash: $0.1.hash,
                     newHash: $0.local.hash)
        }
        
        return ProjectDiff(files: files)
    }
}
