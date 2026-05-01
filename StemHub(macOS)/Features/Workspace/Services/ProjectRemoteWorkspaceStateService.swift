//
//  ProjectRemoteWorkspaceStateService.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

protocol ProjectRemoteWorkspaceStateManaging {
    func persistWorkspaceState(projectID: String, currentBranch: Branch) async throws
}

final class ProjectRemoteWorkspaceStateService: ProjectRemoteWorkspaceStateManaging {
    private let projectRepository: any ProjectWorkspaceStateUpdating

    init(projectRepository: any ProjectWorkspaceStateUpdating) {
        self.projectRepository = projectRepository
    }

    func persistWorkspaceState(projectID: String, currentBranch: Branch) async throws {
        try await projectRepository.updateWorkspaceState(
            projectID: projectID,
            currentBranchID: currentBranch.id,
            currentVersionID: currentBranch.headVersionID
        )
    }
}
