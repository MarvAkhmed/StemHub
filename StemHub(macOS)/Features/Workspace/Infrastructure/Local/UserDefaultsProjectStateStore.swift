//
//  UserDefaultsProjectStateStore.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

struct UserDefaultsProjectStateStore: ProjectStateStore {
    nonisolated(unsafe) private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    nonisolated func syncState(for projectID: String) -> ProjectSyncState {
        guard
            let data = defaults.data(forKey: stateKey(for: projectID)),
            let state = try? JSONDecoder().decode(ProjectSyncState.self, from: data)
        else {
            return .empty(projectID: projectID)
        }

        return state
    }

    nonisolated func saveSyncState(_ state: ProjectSyncState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey(for: state.projectID))
    }

    nonisolated func bookmarkData(for projectID: String) -> Data? {
        defaults.data(forKey: bookmarkKey(for: projectID))
    }

    nonisolated func saveBookmarkData(_ data: Data, for projectID: String) {
        defaults.set(data, forKey: bookmarkKey(for: projectID))
    }

    nonisolated func removeSyncState(for projectID: String) {
        defaults.removeObject(forKey: stateKey(for: projectID))
    }

    nonisolated func removeBookmarkData(for projectID: String) {
        defaults.removeObject(forKey: bookmarkKey(for: projectID))
    }

    nonisolated private func stateKey(for projectID: String) -> String {
        "project_\(projectID)_syncState"
    }

    nonisolated private func bookmarkKey(for projectID: String) -> String {
        "project_\(projectID)_bookmark"
    }
}

typealias DefaultProjectPersistenceStrategy = UserDefaultsProjectStateStore
