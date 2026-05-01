//
//  RemoteSnapshotRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol RemoteSnapshotRepository: Sendable {
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
}
