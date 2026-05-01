//
//  CommitFileSnapshot.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct CommitFileSnapshot: Codable, Sendable {
    let fileID: String
    let path: String
    let blobID: String
    /// Exact SHA-256 of the raw file bytes. This is Git/blob identity, not audio identity.
    let hash: String
    let versionNumber: Int

    nonisolated var fileHash: String { hash }
}
