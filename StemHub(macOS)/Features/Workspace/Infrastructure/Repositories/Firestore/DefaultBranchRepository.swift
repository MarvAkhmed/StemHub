//
//  DefaultBranchRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

final class DefaultBranchRepository: BranchRepository {
    private let strategy: FirestoreBranchStrategy

    init(strategy: FirestoreBranchStrategy) {
        self.strategy = strategy
    }

    func fetchBranches(projectID: String) async throws -> [Branch] {
        try await strategy.fetchBranches(projectID: projectID)
    }

    func fetchBranch(branchID: String) async throws -> Branch? {
        try await strategy.fetchBranch(branchID: branchID)
    }

    func fetchHeadVersionID(branchID: String) async throws -> String? {
        try await strategy.fetchBranch(branchID: branchID)?.headVersionID
    }

    func createBranch(
        projectID: String,
        name: String,
        headVersionID: String?,
        createdBy: String
    ) async throws -> Branch {
        try await strategy.createBranch(
            projectID: projectID,
            name: name,
            headVersionID: headVersionID,
            createdBy: createdBy
        )
    }
}
