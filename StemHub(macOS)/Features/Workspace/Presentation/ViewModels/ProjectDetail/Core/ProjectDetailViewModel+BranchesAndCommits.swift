//
//  ProjectDetailViewModel+BranchesAndCommits.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

extension ProjectDetailViewModel {
    func switchBranch(_ branchID: String) async {
        await performActivity(.switchingBranch) {
            let result = try await dependencies.branchWorkflowService.switchBranch(
                project: project,
                selectedBranchID: branchID,
                currentBranchID: workspace.currentBranch?.id
            )

            applyBranchWorkspace(result.branchWorkspace, preserveSelectedVersionID: nil)
            ui.showRelocationAlert = result.needsRelocation
            try await refreshWorkspaceState(includeCollaborationData: false)
        }
    }

    func createBranch() async {
        guard let currentUserID else {
            ui.errorMessage = ProjectDetailError.userNotSignedIn.localizedDescription
            return
        }

        let branchName = ui.newBranchName.trimmed

        await performActivity(.creatingBranch) {
            try await dependencies.branchWorkflowService.createBranch(
                project: project,
                name: branchName,
                sourceVersionID: currentHeadVersionID,
                createdBy: currentUserID
            )

            ui.newBranchName = ""
            try await refreshWorkspaceState(includeCollaborationData: false)
        }
    }

    func pullLatest() async {
        await performActivity(.pulling) {
            guard let branch = resolvedBranch else {
                throw ProjectDetailError.missingBranch
            }

            try await dependencies.branchWorkflowService.pullLatest(projectID: project.id, branch: branch)
            try await refreshWorkspaceState(includeCollaborationData: false)
        }
    }

    func prepareCommitDraft(message: String, stagedFiles: [LocalFile]?) async -> Commit? {
        do {
            return try await createCommitDraft(
                message: message,
                stagedFiles: stagedFiles
            )
        } catch {
            ui.errorMessage = error.localizedDescription
            return nil
        }
    }

    func stageCommitDraft(_ draft: Commit) async {
        await performActivity(.committing) {
            try await cacheCommitDraft(draft)
        }
    }

    func pushAllCommits() async {
        await performActivity(.pushing) {
            guard let branch = resolvedBranch else {
                throw ProjectDetailError.missingBranch
            }

            let result = try await dependencies.commitWorkflowService.pushAllCommits(
                projectID: project.id,
                branchID: branch.id
            )

            workspace.localCommits = result.remainingCommits
            if let latestVersionID = result.latestVersionID {
                applyNewHeadVersion(latestVersionID)
            }

            try await refreshWorkspaceState(includeCollaborationData: false)
        }
    }

    func createCommitDraft(message: String,
                           stagedFiles: [LocalFile]?
    ) async throws -> Commit {
        guard let currentUserID else {
            throw ProjectDetailError.userNotSignedIn
        }

        guard let branch = resolvedBranch else {
            throw ProjectDetailError.missingBranch
        }

        return try await dependencies.commitWorkflowService.createCommitDraft(
            projectID: project.id,
            branchID: branch.id,
            stagedFiles: stagedFiles ?? [],
            userID: currentUserID,
            message: message.trimmed
        )
    }

    func cacheCommitDraft(_ commit: Commit) async throws {
        guard let branch = resolvedBranch else {
            throw ProjectDetailError.missingBranch
        }

        workspace.localCommits = try await dependencies.commitWorkflowService.stageCommit(
            commit,
            projectID: project.id,
            branchID: branch.id
        )
    }

    func applyNewHeadVersion(_ versionID: String) {
        guard var branch = workspace.currentBranch else { return }

        branch.updateHeadVersion(to: versionID)
        workspace.currentBranch = branch
        project.currentVersionID = versionID
    }
}
