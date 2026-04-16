//
//  ProjectVersion.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct ProjectVersion: Identifiable, Codable {
    let id: String
    let projectID: String
    let versionNumber: Int
    let parentVersionID: String?
    let fileVersionIDs: [String] // snapshot
    let createdBy: String
    let createdAt: Date
    let notes: String?
    let diff: ProjectDiff
    let commitId: String?
}
