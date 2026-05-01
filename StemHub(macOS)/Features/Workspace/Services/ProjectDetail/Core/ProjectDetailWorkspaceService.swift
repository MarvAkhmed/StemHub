//
//  ProjectDetailWorkspaceService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectDetailWorkspaceSnapshot {
    let branchWorkspace: BranchWorkspaceState
    let localCommits: [LocalCommit]
    let fileTree: [FileTreeNode]
    let band: Band?
    let members: [User]?
    let pendingInvitations: [BandInvitation]?
}

protocol ProjectDetailWorkspaceLoading {
    func loadSnapshot(
        project: Project,
        currentBranchID: String?,
        includeCollaborationData: Bool,
        needsCollaborationData: Bool
    ) async throws -> ProjectDetailWorkspaceSnapshot
}

final class ProjectDetailWorkspaceService: ProjectDetailWorkspaceLoading {
    private let branchService: ProjectBranchServiceProtocol
    private let localWorkspace: ProjectLocalWorkspaceService
    private let workspaceStateService: ProjectWorkspaceStateManaging
    private let collaborationService: ProjectCollaborationServiceProtocol

    init(
        branchService: ProjectBranchServiceProtocol,
        localWorkspace: ProjectLocalWorkspaceService,
        workspaceStateService: ProjectWorkspaceStateManaging,
        collaborationService: ProjectCollaborationServiceProtocol
    ) {
        self.branchService = branchService
        self.localWorkspace = localWorkspace
        self.workspaceStateService = workspaceStateService
        self.collaborationService = collaborationService
    }

    func loadSnapshot(project: Project,
                      currentBranchID: String?,
                      includeCollaborationData: Bool,
                      needsCollaborationData: Bool
    ) async throws -> ProjectDetailWorkspaceSnapshot {
        let preferredBranchID = workspaceStateService.currentBranchID(for: project.id)?.nonEmpty
        ?? currentBranchID
        ?? project.currentBranchID

        async let branchWorkspace = branchService.loadBranchWorkspace(
            projectID: project.id,
            selectedBranchID: preferredBranchID,
            fallbackBranchID: project.currentBranchID
        )
        async let localCommits = localWorkspace.loadLocalCommits(projectID: project.id)
        async let fileTree = localWorkspace.loadFileTree(projectID: project.id)

        let shouldLoadCollaboration = includeCollaborationData || needsCollaborationData
        var band: Band?
        var members: [User]?
        var pendingInvitations: [BandInvitation]?

        if shouldLoadCollaboration {
            async let fetchedBand = collaborationService.fetchBand(bandID: project.bandID)
            async let fetchedMembers = collaborationService.fetchMembers(bandID: project.bandID)
            async let fetchedPendingInvitations = collaborationService.fetchPendingInvitations(bandID: project.bandID)

            band = try await fetchedBand
            members = try await fetchedMembers
            pendingInvitations = try await fetchedPendingInvitations
        }

        return ProjectDetailWorkspaceSnapshot(
            branchWorkspace: try await branchWorkspace,
            localCommits: try await localCommits,
            fileTree: await fileTree,
            band: band,
            members: members,
            pendingInvitations: pendingInvitations
        )
    }
}
