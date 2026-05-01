//
//  LocalFile.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

struct LocalFile: Identifiable, Sendable {
    let id = UUID().uuidString
    let path: String  // relative path inside project
    let name: String
    let fileExtension: String
    let size: Int64
    /// Exact SHA-256 of the raw file bytes. This is Git/blob identity, not audio identity.
    let hash: String
    let isDirectory: Bool

    nonisolated var fileHash: String { hash }
}
