//
//  DefaultBranchRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

final class DefaultBranchRepository: BranchRepository {
    private let strategy: FirestoreBranchStrategy

    init(strategy: FirestoreBranchStrategy = DefaultFirestoreBranchStrategy()) {
        self.strategy = strategy
    }

    func fetchBranch(branchID: String) async throws -> Branch? {
        try await strategy.fetchBranch(branchID: branchID)
    }

    func fetchHeadVersionID(branchID: String) async throws -> String? {
        try await strategy.fetchBranch(branchID: branchID)?.headVersionID
    }
}
