//
//  ProjectStateStore.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

typealias ProjectPersistenceStrategy = ProjectStateStore

protocol ProjectStateStore {
    nonisolated func syncState(for projectID: String) -> ProjectSyncState
    nonisolated func saveSyncState(_ state: ProjectSyncState)
    nonisolated func bookmarkData(for projectID: String) -> Data?
    nonisolated func saveBookmarkData(_ data: Data, for projectID: String)
    nonisolated func removeSyncState(for projectID: String)
    nonisolated func removeBookmarkData(for projectID: String)
}

extension ProjectStateStore {
    nonisolated func getLocalPath(for projectID: String) -> String {
        syncState(for: projectID).localPath
    }

    nonisolated func setLocalPath(_ path: String, for projectID: String) {
        var state = syncState(for: projectID)
        state.localPath = path
        saveSyncState(state)
    }

    nonisolated func getLastPulledVersionID(for projectID: String) -> String? {
        syncState(for: projectID).lastPulledVersionID
    }

    nonisolated func setLastPulledVersionID(_ versionID: String?, for projectID: String) {
        var state = syncState(for: projectID)
        state.lastPulledVersionID = versionID
        saveSyncState(state)
    }

    nonisolated func setCurrentBranchID(_ branchID: String, for projectID: String) {
        var state = syncState(for: projectID)
        state.currentBranchID = branchID
        saveSyncState(state)
    }

    nonisolated func getCurrentBranchID(for projectID: String) -> String? {
        syncState(for: projectID).currentBranchID
    }

    nonisolated func removePersistence(for projectID: String) {
        removeSyncState(for: projectID)
        removeBookmarkData(for: projectID)
    }
}
