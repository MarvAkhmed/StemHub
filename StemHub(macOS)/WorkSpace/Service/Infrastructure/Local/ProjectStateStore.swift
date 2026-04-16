//
//  ProjectStateStore.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

typealias ProjectPersistenceStrategy = ProjectStateStore

protocol ProjectStateStore {
    func syncState(for projectID: String) -> ProjectSyncState
    func saveSyncState(_ state: ProjectSyncState)
    func bookmarkData(for projectID: String) -> Data?
    func saveBookmarkData(_ data: Data, for projectID: String)
}

extension ProjectStateStore {
    func getLocalPath(for projectID: String) -> String {
        syncState(for: projectID).localPath
    }

    func setLocalPath(_ path: String, for projectID: String) {
        var state = syncState(for: projectID)
        state.localPath = path
        saveSyncState(state)
    }

    func getLastPulledVersionID(for projectID: String) -> String? {
        syncState(for: projectID).lastPulledVersionID
    }

    func setLastPulledVersionID(_ versionID: String?, for projectID: String) {
        var state = syncState(for: projectID)
        state.lastPulledVersionID = versionID
        saveSyncState(state)
    }

    func setCurrentBranchID(_ branchID: String, for projectID: String) {
        var state = syncState(for: projectID)
        state.currentBranchID = branchID
        saveSyncState(state)
    }

    func getCurrentBranchID(for projectID: String) -> String? {
        syncState(for: projectID).currentBranchID
    }
}


