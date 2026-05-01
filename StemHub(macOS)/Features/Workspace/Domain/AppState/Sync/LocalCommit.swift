//
//  LocalCommit.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct LocalCommit: Codable {
    let id: String
    let parentCommitID: String?
    let commit: Commit
    let cachedFolderURL: URL
    var isPushed: Bool
    let createdAt: Date
}
