//
//  LocalCommitStorageService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

protocol LocalCommitService {
    func loadLocalCommits(projectID: String) -> [LocalCommit]
    func saveLocalCommits(_ commits: [LocalCommit], for projectID: String)
    func cacheFolder(for projectID: String) -> URL
    func loadLocalCommitsAndCleanup(projectID: String) -> [LocalCommit]
}

final class DefaultLocalCommitService: LocalCommitService {
    private let fileManager = FileManager.default
    
    func cacheFolder(for projectID: String) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let baseFolder = appSupport.appendingPathComponent("StemHub/Commits", isDirectory: true)
        try? fileManager.createDirectory(at: baseFolder, withIntermediateDirectories: true)
        let projectFolder = baseFolder.appendingPathComponent(projectID, isDirectory: true)
        try? fileManager.createDirectory(at: projectFolder, withIntermediateDirectories: true)
        return projectFolder
    }
    
    private func commitsFileURL(for projectID: String) -> URL {
        cacheFolder(for: projectID).appendingPathComponent("local_commits.json")
    }
    
    func loadLocalCommits(projectID: String) -> [LocalCommit] {
        let url = commitsFileURL(for: projectID)
        guard let data = try? Data(contentsOf: url),
              let commits = try? JSONDecoder().decode([LocalCommit].self, from: data) else {
            return []
        }
        return commits
    }
    
    func saveLocalCommits(_ commits: [LocalCommit], for projectID: String) {
        let url = commitsFileURL(for: projectID)
        guard let data = try? JSONEncoder().encode(commits) else { return }
        try? data.write(to: url)
    }
    
    func cleanupOrphanedFolders(projectID: String, validCommitIDs: Set<String>) {
        let projectFolder = cacheFolder(for: projectID)
        guard let contents = try? fileManager.contentsOfDirectory(at: projectFolder, includingPropertiesForKeys: nil) else { return }
        for url in contents where url.hasDirectoryPath {
            let commitID = url.lastPathComponent
            if !validCommitIDs.contains(commitID) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
    
    func loadLocalCommitsAndCleanup(projectID: String) -> [LocalCommit] {
        let commits = loadLocalCommits(projectID: projectID)
        let validIDs = Set(commits.map { $0.id })
        cleanupOrphanedFolders(projectID: projectID, validCommitIDs: validIDs)
        return commits
    }
}
