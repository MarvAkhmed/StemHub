//
//  LocalCommitStore.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation


typealias LocalCommitService = LocalCommitStore
protocol LocalCommitStore {
    nonisolated func loadLocalCommits(projectID: String) -> [LocalCommit]
    nonisolated func saveLocalCommits(_ commits: [LocalCommit], for projectID: String)
    nonisolated func cacheFolder(for projectID: String) -> URL
    nonisolated func loadLocalCommitsAndCleanup(projectID: String) -> [LocalCommit]
    nonisolated func removeCache(for projectID: String)
}

typealias DefaultLocalCommitService = DefaultLocalCommitStore


final class DefaultLocalCommitStore: LocalCommitStore {
    nonisolated(unsafe) private let fileManager = FileManager.default

    nonisolated func cacheFolder(for projectID: String) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let baseFolder = appSupport.appendingPathComponent("StemHub/Commits", isDirectory: true)
        try? fileManager.createDirectory(at: baseFolder, withIntermediateDirectories: true)

        let projectFolder = baseFolder.appendingPathComponent(projectID, isDirectory: true)
        try? fileManager.createDirectory(at: projectFolder, withIntermediateDirectories: true)
        return projectFolder
    }

    nonisolated func loadLocalCommits(projectID: String) -> [LocalCommit] {
        let url = commitsFileURL(for: projectID)
        guard
            let data = try? Data(contentsOf: url),
            let commits = try? JSONDecoder().decode([LocalCommit].self, from: data)
        else {
            return []
        }

        return commits
    }

    nonisolated func saveLocalCommits(_ commits: [LocalCommit], for projectID: String) {
        let url = commitsFileURL(for: projectID)
        guard let data = try? JSONEncoder().encode(commits) else { return }
        try? data.write(to: url)
    }

    nonisolated func loadLocalCommitsAndCleanup(projectID: String) -> [LocalCommit] {
        let commits = loadLocalCommits(projectID: projectID)
        let validIDs = Set(commits.map(\.id))
        cleanupOrphanedFolders(projectID: projectID, validCommitIDs: validIDs)
        return commits
    }

    nonisolated func removeCache(for projectID: String) {
        let projectFolder = cacheFolder(for: projectID)
        try? fileManager.removeItem(at: projectFolder)
    }

    nonisolated private func commitsFileURL(for projectID: String) -> URL {
        cacheFolder(for: projectID).appendingPathComponent("local_commits.json")
    }

    nonisolated private func cleanupOrphanedFolders(projectID: String, validCommitIDs: Set<String>) {
        let projectFolder = cacheFolder(for: projectID)
        guard let contents = try? fileManager.contentsOfDirectory(at: projectFolder, includingPropertiesForKeys: nil) else {
            return
        }

        for url in contents where url.hasDirectoryPath {
            if !validCommitIDs.contains(url.lastPathComponent) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
