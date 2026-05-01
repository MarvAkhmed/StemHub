//
//  LocalCommitCacheActor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

actor LocalCommitCacheActor {
    private let store: LocalCommitStore

    init(store: LocalCommitStore) {
        self.store = store
    }

    func loadLocalCommits(projectID: String) throws -> [LocalCommit] {
        try store.loadLocalCommits(projectID: projectID)
    }

    func loadLocalCommitsAndCleanup(projectID: String) throws -> [LocalCommit] {
        try store.loadLocalCommitsAndCleanup(projectID: projectID)
    }

    func saveLocalCommits(_ commits: [LocalCommit], for projectID: String) throws {
        try store.saveLocalCommits(commits, for: projectID)
    }

    func cacheFolder(for projectID: String) throws -> URL {
        try store.cacheFolder(for: projectID)
    }

    func removeCache(for projectID: String) throws {
        try store.removeCache(for: projectID)
    }
}
