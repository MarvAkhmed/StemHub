//
//  FileDiff.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileDiff: Codable, Sendable {
    let path: String
    let changeType: ChangeType
    let oldPath: String? // for rename
    let oldHash: String?
    let newHash: String?
}

enum ChangeType: String, Codable, Sendable {
    case added
    case modified
    case removed
    case renamed
}
