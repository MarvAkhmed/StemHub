//
//  BranchRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

protocol BranchRepository {
    func fetchBranches(projectID: String) async throws -> [Branch]
    func fetchBranch(branchID: String) async throws -> Branch?
    func fetchHeadVersionID(branchID: String) async throws -> String?
    func createBranch(
        projectID: String,
        name: String,
        headVersionID: String?,
        createdBy: String
    ) async throws -> Branch
}
