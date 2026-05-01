//
//  ProjectWorkspaceStateService.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

protocol ProjectWorkspaceStateManaging {
    func state(for projectID: String) -> ProjectSyncState
    func currentBranchID(for projectID: String) -> String?
    func setCurrentBranchID(_ branchID: String, for projectID: String)
    func markCommitCached(projectID: String, commitID: String, branchID: String)
}

final class ProjectWorkspaceStateService: ProjectWorkspaceStateManaging {
    private let stateStore: ProjectStateStore

    init(stateStore: ProjectStateStore) {
        self.stateStore = stateStore
    }

    func state(for projectID: String) -> ProjectSyncState {
        stateStore.syncState(for: projectID)
    }

    func currentBranchID(for projectID: String) -> String? {
        stateStore.currentBranchID(for: projectID)
    }

    func setCurrentBranchID(_ branchID: String, for projectID: String) {
        stateStore.setCurrentBranchID(branchID, for: projectID)
    }

    func markCommitCached(projectID: String, commitID: String, branchID: String) {
        var state = stateStore.syncState(for: projectID)
        state.lastCommittedID = commitID
        state.currentBranchID = branchID
        stateStore.saveSyncState(state)
    }
}
