//
//  ProjectBranchService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol ProjectBranchServiceProtocol {
    func loadBranchWorkspace(projectID: String, selectedBranchID: String,
                             fallbackBranchID: String) async throws -> BranchWorkspaceState

    func createBranch(projectID: String, name: String, sourceVersionID: String?,
                      createdBy: String) async throws -> Branch
}

final class ProjectBranchService: ProjectBranchServiceProtocol {
    private let branchRepository: BranchRepository
    private let versionRepository: VersionRepository

    init(
        branchRepository: BranchRepository,
        versionRepository: VersionRepository
    ) {
        self.branchRepository = branchRepository
        self.versionRepository = versionRepository
    }

    func loadBranchWorkspace(projectID: String, selectedBranchID: String,
                             fallbackBranchID: String) async throws -> BranchWorkspaceState {
        
        let branches = try await branchRepository.fetchBranches(projectID: projectID)
        let resolvedBranch = try resolveSelectedBranch(
            branches: branches,
            selectedBranchID: selectedBranchID,
            fallbackBranchID: fallbackBranchID
        )
        let history = try await fetchVersionLineage(headVersionID: resolvedBranch.headVersionID)

        return BranchWorkspaceState(branches: branches, selectedBranch: resolvedBranch,
                                    versionHistory: history, headVersionID: resolvedBranch.headVersionID)
    }

    func createBranch(projectID: String, name: String, sourceVersionID: String?,
                      createdBy: String) async throws -> Branch {
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ProjectBranchError.invalidName
        }

        let existingBranches = try await branchRepository.fetchBranches(projectID: projectID)
        if existingBranches.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            throw ProjectBranchError.duplicateName
        }

        return try await branchRepository.createBranch(
            projectID: projectID,
            name: trimmedName,
            headVersionID: sourceVersionID,
            createdBy: createdBy
        )
    }
}

private extension ProjectBranchService {
    func resolveSelectedBranch(branches: [Branch], selectedBranchID: String,
                               fallbackBranchID: String) throws -> Branch {
        
        if let selectedBranch = branches.first(where: { $0.id == selectedBranchID }) {
            return selectedBranch
        }

        if let fallbackBranch = branches.first(where: { $0.id == fallbackBranchID }) {
            return fallbackBranch
        }

        throw SyncError.branchNotFound
    }

    func fetchVersionLineage(headVersionID: String?) async throws -> [ProjectVersion] {
        guard let headVersionID, !headVersionID.isEmpty else { return [] }

        var versions: [ProjectVersion] = []
        var nextVersionID: String? = headVersionID

        while let versionID = nextVersionID,
              let version = try await versionRepository.fetchVersion(versionID: versionID) {
            versions.append(version)
            nextVersionID = version.parentVersionID
        }

        return versions
    }
}
