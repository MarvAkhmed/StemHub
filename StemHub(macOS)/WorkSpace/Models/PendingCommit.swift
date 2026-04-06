//
//  PendingCommit.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct PendingCommit {
    var files: [CommitFileSnapshot]
    var diff: ProjectDiff
    var message: String
}
