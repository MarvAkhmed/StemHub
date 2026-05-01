//
//  LocalCommitJSONStore.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

protocol LocalCommitJSONStoring: Sendable {
    nonisolated func load(from url: URL) throws -> [LocalCommit]
    nonisolated func save(_ commits: [LocalCommit], to url: URL) throws
}

struct DefaultLocalCommitJSONStore: LocalCommitJSONStoring {
    nonisolated func load(from url: URL) throws -> [LocalCommit] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([LocalCommit].self, from: data)
    }

    nonisolated func save(_ commits: [LocalCommit], to url: URL) throws {
        let data = try JSONEncoder().encode(commits)
        try data.write(to: url, options: .atomic)
    }
}
