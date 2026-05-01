//
//  ProjectDetailBranchWorkflowService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectBranchSwitchResult {
    let branchWorkspace: BranchWorkspaceState
    let needsRelocation: Bool
}

protocol ProjectDetailBranchWorkflowing {
    func switchBranch(
        project: Project,
        selectedBranchID: String,
        currentBranchID: String?
    ) async throws -> ProjectBranchSwitchResult

    func createBranch(
        project: Project,
        name: String,
        sourceVersionID: String?,
        createdBy userID: String
    ) async throws

    func pullLatest(projectID: String, branch: Branch) async throws
}

final class ProjectDetailBranchWorkflowService: ProjectDetailBranchWorkflowing {
    private let branchService: ProjectBranchServiceProtocol
    private let localWorkspace: ProjectLocalWorkspaceService
    private let syncService: ProjectSyncService
    private let workspaceStateService: ProjectWorkspaceStateManaging
    private let remoteStateService: ProjectRemoteWorkspaceStateManaging

    init(
        branchService: ProjectBranchServiceProtocol,
        localWorkspace: ProjectLocalWorkspaceService,
        syncService: ProjectSyncService,
        workspaceStateService: ProjectWorkspaceStateManaging,
        remoteStateService: ProjectRemoteWorkspaceStateManaging
    ) {
        self.branchService = branchService
        self.localWorkspace = localWorkspace
        self.syncService = syncService
        self.workspaceStateService = workspaceStateService
        self.remoteStateService = remoteStateService
    }

    func switchBranch(
        project: Project,
        selectedBranchID: String,
        currentBranchID: String?
    ) async throws -> ProjectBranchSwitchResult {
        let branchWorkspace = try await branchService.loadBranchWorkspace(
            projectID: project.id,
            selectedBranchID: selectedBranchID,
            fallbackBranchID: currentBranchID ?? project.currentBranchID
        )

        let selectedBranch = branchWorkspace.selectedBranch
        try await localWorkspace.ensureProjectFolderWritable(projectID: project.id)
        _ = try await syncService.pull(projectID: project.id, branchID: selectedBranch.id)
        try await remoteStateService.persistWorkspaceState(
            projectID: project.id,
            currentBranch: selectedBranch
        )

        return ProjectBranchSwitchResult(
            branchWorkspace: branchWorkspace,
            needsRelocation: false
        )
    }

    func createBranch(
        project: Project,
        name: String,
        sourceVersionID: String?,
        createdBy userID: String
    ) async throws {
        let branch = try await branchService.createBranch(
            projectID: project.id,
            name: name,
            sourceVersionID: sourceVersionID,
            createdBy: userID
        )

        workspaceStateService.setCurrentBranchID(branch.id, for: project.id)
        try await remoteStateService.persistWorkspaceState(
            projectID: project.id,
            currentBranch: branch
        )
    }

    func pullLatest(projectID: String, branch: Branch) async throws {
        try await localWorkspace.ensureProjectFolderWritable(projectID: projectID)
        _ = try await syncService.pull(projectID: projectID, branchID: branch.id)

        try await remoteStateService.persistWorkspaceState(
            projectID: projectID,
            currentBranch: branch
        )
    }
}
