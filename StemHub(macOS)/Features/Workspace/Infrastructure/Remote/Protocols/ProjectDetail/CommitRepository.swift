//
//  CommitRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol RemoteCommitPersisting: Sendable {
    func persistCommitPush(_ push: PreparedCommitPush, branchID: String) async throws -> ProjectVersion
}

protocol RemoteCommitRepository: RemoteCommitPersisting {}

protocol CommitRepository: RemoteCommitRepository {}
