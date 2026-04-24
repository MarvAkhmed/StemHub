//
//  ProjectFolderMetadataService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol ProjectFolderMetadataProviding {
    func describeFolder(at url: URL) async throws -> CreateProjectFolderMetadata
}

struct ProjectFolderMetadataService: ProjectFolderMetadataProviding {
    func describeFolder(at url: URL) async throws -> CreateProjectFolderMetadata {
        try await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            let resourceKeys: Set<URLResourceKey> = [
                .isRegularFileKey,
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey
            ]

            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )

            let rootValues = try? url.resourceValues(forKeys: resourceKeys)
            var subfolderCount = 0
            var totalFileCount = 0
            var audioFileCount = 0
            var midiFileCount = 0
            var totalBytes: Int64 = 0
            var lastModifiedAt = rootValues?.contentModificationDate

            while let item = enumerator?.nextObject() as? URL {
                let values = try item.resourceValues(forKeys: resourceKeys)

                if values.isDirectory == true {
                    subfolderCount += 1
                    if let modifiedAt = values.contentModificationDate {
                        lastModifiedAt = max(lastModifiedAt ?? modifiedAt, modifiedAt)
                    }
                    continue
                }

                guard values.isRegularFile == true else { continue }
                totalFileCount += 1
                totalBytes += Int64(values.fileSize ?? 0)

                switch item.pathExtension.lowercased() {
                case "mid", "midi":
                    midiFileCount += 1
                case "mp3", "wav", "aif", "aiff", "m4a", "aac", "flac", "ogg":
                    audioFileCount += 1
                default:
                    break
                }

                if let modifiedAt = values.contentModificationDate {
                    lastModifiedAt = max(lastModifiedAt ?? modifiedAt, modifiedAt)
                }
            }

            return CreateProjectFolderMetadata(
                folderName: url.lastPathComponent,
                folderPath: url.path,
                subfolderCount: subfolderCount,
                totalFileCount: totalFileCount,
                audioFileCount: audioFileCount,
                midiFileCount: midiFileCount,
                totalBytes: totalBytes,
                lastModifiedAt: lastModifiedAt
            )
        }.value
    }
}
