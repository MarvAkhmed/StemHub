//
//  DefaultCommitRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

final class DefaultCommitRepository: CommitRepository {
    private let strategy: CommitStorageStrategy

    init(strategy: CommitStorageStrategy = DefaultCommitStorageStrategy()) {
        self.strategy = strategy
    }

    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        try await strategy.saveCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }
}
