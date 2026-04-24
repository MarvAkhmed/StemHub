//
//  RemoteSnapshotRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

protocol RemoteSnapshotRepository {
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
}
