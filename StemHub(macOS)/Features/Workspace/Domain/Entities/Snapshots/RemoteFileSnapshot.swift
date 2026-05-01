//
//  RemoteFileSnapshot.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct RemoteFileSnapshot: Sendable {
    let id: String
    let fileID: String
    let path: String
    /// Exact SHA-256 of the raw file bytes. This is Git/blob identity, not audio identity.
    let hash: String
    let versionID: String
    let versionNumber: Int

    nonisolated var fileHash: String { hash }

    init(fileID: String,
         path: String,
         hash: String,
         versionID: String,
         versionNumber: Int = 1) {
        self.id = fileID
        self.fileID = fileID
        self.path = path
        self.hash = hash
        self.versionID = versionID
        self.versionNumber = versionNumber
    }
}
