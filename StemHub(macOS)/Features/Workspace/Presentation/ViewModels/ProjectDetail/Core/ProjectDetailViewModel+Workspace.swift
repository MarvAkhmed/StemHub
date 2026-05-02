//
//  ProjectDetailViewModel+Workspace.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

extension ProjectDetailViewModel {
    func loadInitialStateIfNeeded() async {
        guard !hasLoadedInitialState else { return }

        await performActivity(.loading) {
            try await refreshWorkspaceState()
            hasLoadedInitialState = true
        }
    }

    func loadVersionHistory() async {
        await performActivity(.loading) {
            try await refreshWorkspaceState(
                preserveSelectedVersionID: workspace.selectedVersion?.id,
                includeCollaborationData: false
            )
        }
    }

    func loadFiles() async {
        await performActivity(.loading) {
            workspace.selectedVersion = nil
            workspace.versionDiff = nil
            try await refreshWorkspaceState(includeCollaborationData: false)
        }
    }

    func loadVersionDetails(versionID: String) async {
        await performActivity(.loading) {
            let selection = try await dependencies.versionWorkflowService.loadVersionDetails(
                versionID: versionID,
                versionHistory: workspace.versionHistory
            )

            workspace.selectedVersion = selection.version
            workspace.versionDiff = selection.diff
            try await refreshComments(forceRefresh: true)
        }
    }

    func refreshWorkspaceState(
        preserveSelectedVersionID: String? = nil,
        includeCollaborationData: Bool = true
    ) async throws {
        let snapshot = try await dependencies.detailWorkspaceService.loadSnapshot(
            project: project,
            currentBranchID: workspace.currentBranch?.id,
            includeCollaborationData: includeCollaborationData,
            needsCollaborationData: collaboration.band == nil || collaboration.members.isEmpty
        )

        applyBranchWorkspace(
            snapshot.branchWorkspace,
            preserveSelectedVersionID: preserveSelectedVersionID
        )

        workspace.localCommits = snapshot.localCommits
        workspace.fileTree = snapshot.fileTree

        if let band = snapshot.band {
            collaboration.band = band
        }

        if let members = snapshot.members {
            collaboration.members = members
        }

        if let pendingInvitations = snapshot.pendingInvitations {
            collaboration.pendingInvitations = pendingInvitations
        }

        await restoreSelectedFileSelection()
        try await refreshComments(forceRefresh: true)
    }

    func applyBranchWorkspace(_ branchWorkspace: BranchWorkspaceState, preserveSelectedVersionID: String? = nil) {
        workspace.branches = branchWorkspace.branches
        workspace.currentBranch = branchWorkspace.selectedBranch
        workspace.versionHistory = branchWorkspace.versionHistory
        project.currentBranchID = branchWorkspace.selectedBranch.id
        project.currentVersionID = branchWorkspace.headVersionID ?? ""

        workspace.selectedVersion = workspace.versionHistory.version(matching: preserveSelectedVersionID)
        workspace.versionDiff = workspace.selectedVersion?.diff
        comments.loadedCommentsVersionID = nil
    }
}
