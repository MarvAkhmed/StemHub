//
//  DefaultVersionRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

final class DefaultVersionRepository: VersionRepository {
    private let strategy: FirestoreVersionStrategy

    init(strategy: FirestoreVersionStrategy = DefaultFirestoreVersionStrategy()) {
        self.strategy = strategy
    }

    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        try await strategy.fetchVersionHistory(projectID: projectID)
    }

    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        try await strategy.fetchVersion(versionID: versionID)
    }

    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion] {
        try await strategy.fetchFileVersions(fileVersionIDs: fileVersionIDs)
    }
}
