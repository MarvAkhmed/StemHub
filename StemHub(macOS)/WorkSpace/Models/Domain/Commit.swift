//
//  Commit.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct Commit: Identifiable, Codable {
    let id: String
    let projectID: String
    let parentCommitID: String? //  chain
    let basedOnVersionID: String //  what you pulled from(remote version commit is based on)
    let diff: ProjectDiff
    let fileSnapshot: [CommitFileSnapshot]
    let createdBy: String
    let createdAt: Date
    let message: String?
    var status: CommitStatus
}

enum CommitStatus: String, Codable {
    case local,  pushing, pushed,  failed,  pending
}
