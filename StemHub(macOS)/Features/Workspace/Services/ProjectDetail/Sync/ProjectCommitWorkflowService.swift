//
//  ProjectCommitWorkflowService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectCommitPushResult {
    let remainingCommits: [LocalCommit]
    let latestVersionID: String?
}

protocol ProjectCommitWorkflowing {
    func createCommitDraft(projectID: String,
                           branchID: String,
                           stagedFiles: [LocalFile],
                           userID: String,
                           message: String) async throws -> Commit

    func stageCommit(_ commit: Commit,
                     projectID: String,
                     branchID: String) async throws -> [LocalCommit]

    func pushAllCommits(projectID: String, branchID: String) async throws -> ProjectCommitPushResult
}

final class ProjectCommitWorkflowService: ProjectCommitWorkflowing {
    private let syncService: ProjectSyncService
    private let localWorkspace: ProjectLocalWorkspaceService
    private let workspaceStateService: ProjectWorkspaceStateManaging

    init(
        syncService: ProjectSyncService,
        localWorkspace: ProjectLocalWorkspaceService,
        workspaceStateService: ProjectWorkspaceStateManaging
    ) {
        self.syncService = syncService
        self.localWorkspace = localWorkspace
        self.workspaceStateService = workspaceStateService
    }

    func createCommitDraft(
        projectID: String,
        branchID: String,
        stagedFiles: [LocalFile],
        userID: String,
        message: String
    ) async throws -> Commit {
        try await localWorkspace.ensureProjectFolderWritable(projectID: projectID)
        try await syncService.ensureRemoteHeadIsCurrent(projectID: projectID, branchID: branchID)
        let parentCommitID = try await localWorkspace.latestLocalCommitID(projectID: projectID)

        return try await syncService.createCommit(
            projectID: projectID,
            branchID: branchID,
            stagedFiles: stagedFiles,
            userID: userID,
            message: message,
            parentCommitID: parentCommitID
        )
    }

    func stageCommit(
        _ commit: Commit,
        projectID: String,
        branchID: String
    ) async throws -> [LocalCommit] {
        let stagedCommits = try await localWorkspace.stageCommit(commit, projectID: projectID)

        workspaceStateService.markCommitCached(
            projectID: projectID,
            commitID: commit.id,
            branchID: branchID
        )

        return stagedCommits
    }

    func pushAllCommits(
        projectID: String,
        branchID: String
    ) async throws -> ProjectCommitPushResult {
        var pendingCommits = try await localWorkspace.loadLocalCommits(projectID: projectID)
        var latestVersionID: String?

        for localCommit in pendingCommits.sorted(by: { $0.createdAt < $1.createdAt }) {
            let pushedVersion = try await syncService.pushCommitResolvingOutdatedHead(
                localCommit,
                branchID: branchID
            )
            pendingCommits = try await localWorkspace.removeCommit(
                id: localCommit.id,
                projectID: projectID
            )
            latestVersionID = pushedVersion.id
        }

        return ProjectCommitPushResult(
            remainingCommits: pendingCommits,
            latestVersionID: latestVersionID
        )
    }
}
