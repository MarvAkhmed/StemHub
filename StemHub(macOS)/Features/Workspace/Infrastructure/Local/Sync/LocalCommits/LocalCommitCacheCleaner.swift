//
//  LocalCommitCacheCleaner.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

protocol LocalCommitCacheCleaning: Sendable {
    nonisolated func cleanupOrphanedFolders(in projectFolder: URL, validCommitIDs: Set<String>) throws
    nonisolated func removeCache(at projectFolder: URL) throws
}

struct DefaultLocalCommitCacheCleaner: LocalCommitCacheCleaning {
    nonisolated func cleanupOrphanedFolders(in projectFolder: URL, validCommitIDs: Set<String>) throws {
        let contents = try FileManager.default.contentsOfDirectory(
            at: projectFolder,
            includingPropertiesForKeys: [.isDirectoryKey]
        )

        for url in contents where url.hasDirectoryPath {
            guard !validCommitIDs.contains(url.lastPathComponent) else { continue }
            try FileManager.default.removeItem(at: url)
        }
    }

    nonisolated func removeCache(at projectFolder: URL) throws {
        guard FileManager.default.fileExists(atPath: projectFolder.path) else { return }
        try FileManager.default.removeItem(at: projectFolder)
    }
}
