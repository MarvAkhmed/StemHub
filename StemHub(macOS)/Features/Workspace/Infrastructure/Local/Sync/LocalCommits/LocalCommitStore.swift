//
//  LocalCommitStore.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol LocalCommitStore: Sendable {
    nonisolated func loadLocalCommits(projectID: String) throws -> [LocalCommit]
    nonisolated func loadLocalCommitsAndCleanup(projectID: String) throws -> [LocalCommit]
    nonisolated func saveLocalCommits(_ commits: [LocalCommit], for projectID: String) throws
    nonisolated func cacheFolder(for projectID: String) throws -> URL
    nonisolated func removeCache(for projectID: String) throws
}

final class DefaultLocalCommitStore: LocalCommitStore, @unchecked Sendable {
    nonisolated private let cacheResolver: LocalCommitCacheResolving
    nonisolated private let jsonStore: LocalCommitJSONStoring
    nonisolated private let cacheCleaner: LocalCommitCacheCleaning

      init(
          cacheResolver: LocalCommitCacheResolving = LocalCommitCacheResolver(),
          jsonStore: LocalCommitJSONStoring = DefaultLocalCommitJSONStore(),
          cacheCleaner: LocalCommitCacheCleaning = DefaultLocalCommitCacheCleaner()
      ) {
          self.cacheResolver = cacheResolver
          self.jsonStore = jsonStore
          self.cacheCleaner = cacheCleaner
      }

    nonisolated func cacheFolder(for projectID: String) throws -> URL {
        try cacheResolver.projectCacheFolder(for: projectID)
    }

    nonisolated func loadLocalCommits(projectID: String) throws -> [LocalCommit] {
        try jsonStore.load(from: cacheResolver.commitsFileURL(for: projectID))
    }

    nonisolated func saveLocalCommits(_ commits: [LocalCommit], for projectID: String) throws {
        let url = try cacheResolver.commitsFileURL(for: projectID)
        try jsonStore.save(commits, to: url)
    }
    
    nonisolated func loadLocalCommitsAndCleanup(projectID: String) throws -> [LocalCommit]  {
        let commits = try loadLocalCommits(projectID: projectID)
        let validIDs = Set(commits.map(\.id))
        let url = try cacheFolder(for: projectID)
        try cacheCleaner.cleanupOrphanedFolders(in: url, validCommitIDs: validIDs)
        return commits
    }
    
    nonisolated func removeCache(for projectID: String) throws {
        let url = try cacheFolder(for: projectID)
        try cacheCleaner.removeCache(at: url)
    }
}
