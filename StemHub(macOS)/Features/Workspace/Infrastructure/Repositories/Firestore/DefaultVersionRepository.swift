//
//  DefaultVersionRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

final class DefaultVersionRepository: VersionRepository {
    private let strategy: FirestoreVersionStrategy

    init(strategy: FirestoreVersionStrategy) {
        self.strategy = strategy
    }

    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        try await strategy.fetchVersionHistory(projectID: projectID)
    }

    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        try await strategy.fetchVersion(versionID: versionID)
    }

    func fetchVersions(versionIDs: [String]) async throws -> [ProjectVersion] {
        try await strategy.fetchVersions(versionIDs: versionIDs)
    }

    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion] {
        try await strategy.fetchFileVersions(fileVersionIDs: fileVersionIDs)
    }

    func approveVersion(versionID: String, approvedBy userID: String) async throws {
        try await strategy.approveVersion(versionID: versionID, approvedBy: userID)
    }
}
