//
//  FileBlob.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileBlob: Identifiable, Codable, Sendable {
    let id: String
    let storagePath: String
    let size: Int64
    /// Exact SHA-256 of the raw file bytes. This is Git/blob identity, not audio identity.
    let hash: String
    let createdAt: Date

    nonisolated var fileHash: String { hash }
}
