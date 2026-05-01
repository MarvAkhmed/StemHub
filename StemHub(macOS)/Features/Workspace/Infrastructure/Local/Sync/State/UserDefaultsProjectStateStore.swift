//
//  UserDefaultsProjectStateStore.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

struct UserDefaultsProjectStateStore: ProjectStateStore, @unchecked Sendable {
    // UserDefaults is documented as thread-safe but is not annotated Sendable in Foundation.
    nonisolated(unsafe) private let defaults: UserDefaults
    nonisolated private let keyBuilder: ProjectStateKeyBuilder
    
    init(
        defaults: UserDefaults = .standard,
        keyBuilder: ProjectStateKeyBuilder = ProjectStateKeyBuilder()
    ) {
        self.defaults = defaults
        self.keyBuilder = keyBuilder
    }

    nonisolated func syncState(for projectID: String) -> ProjectSyncState {
        guard
            let data = defaults.data(forKey: keyBuilder.stateKey(for: projectID)),
            let state = try? JSONDecoder().decode(ProjectSyncState.self, from: data)
        else {
            return .empty(projectID: projectID)
        }

        return state
    }

    nonisolated func saveSyncState(_ state: ProjectSyncState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: keyBuilder.stateKey(for: state.projectID))
    }

    nonisolated func bookmarkData(for projectID: String) -> Data? {
        defaults.data(forKey: keyBuilder.bookmarkKey(for: projectID))
    }

    nonisolated func saveBookmarkData(_ data: Data, for projectID: String) {
        defaults.set(data, forKey: keyBuilder.bookmarkKey(for: projectID))
    }

    nonisolated func removeSyncState(for projectID: String) {
        defaults.removeObject(forKey: keyBuilder.stateKey(for: projectID))
    }

    nonisolated func removeBookmarkData(for projectID: String) {
        defaults.removeObject(forKey: keyBuilder.bookmarkKey(for: projectID))
    }
}
