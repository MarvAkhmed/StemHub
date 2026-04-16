//
//  DefaultRemoteSnapshotRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

final class DefaultRemoteSnapshotRepository: RemoteSnapshotRepository {
    private let network: ProjectNetworkStrategy

    init(network: ProjectNetworkStrategy = DefaultProjectNetworkStrategy()) {
        self.network = network
    }

    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        guard !versionID.isEmpty else { return [] }
        return try await network.fetchRemoteSnapshot(versionID: versionID)
    }
}
