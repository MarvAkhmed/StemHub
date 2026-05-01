//
//  LocalCommitCacheResolving.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

protocol LocalCommitCacheResolving: Sendable {
    nonisolated func projectCacheFolder(for projectID: String) throws -> URL
    nonisolated func commitsFileURL(for projectID: String) throws -> URL
}

struct LocalCommitCacheResolver: LocalCommitCacheResolving {
    nonisolated func projectCacheFolder(for projectID: String) throws -> URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                        in: .userDomainMask).first
        else { throw SyncError.projectNotFound }
        let baseFolder = appSupport.appendingPathComponent("StemHub/Commits", isDirectory: true)
        let projectFolder = baseFolder.appendingPathComponent(projectID, isDirectory: true)
        try FileManager.default.createDirectory(at: projectFolder, withIntermediateDirectories: true)
        return projectFolder
    }
    
    nonisolated func commitsFileURL(for projectID: String) throws -> URL {
        try projectCacheFolder(for: projectID)
            .appendingPathComponent("local_commits.json")
    }
}
