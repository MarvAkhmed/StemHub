//
//  DefaultSyncService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation

protocol ProjectSyncStrategy {
    func commit(localPath: URL, localState: LocalProjectState, remoteSnapshot: [RemoteFileSnapshot], userID: String, message: String) async throws -> Commit
}


struct DefaultProjectSyncStrategy: ProjectSyncStrategy {
    func commit(localPath: URL, localState: LocalProjectState, remoteSnapshot: [RemoteFileSnapshot], userID: String, message: String) async throws -> Commit {
        let orchestrator = SyncOrchestrator()
        return try await orchestrator.commit(
            localPath: localPath,
            localState: localState,
            remoteSnapshot: remoteSnapshot,
            userID: userID,
            message: message
        )
    }
}

