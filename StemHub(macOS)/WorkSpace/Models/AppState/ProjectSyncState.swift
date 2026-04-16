//
//  ProjectSyncState.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

typealias LocalProjectState = ProjectSyncState

struct ProjectSyncState: Codable {
    let projectID: String
    var localPath: String
    var lastPulledVersionID: String? // remote HEAD
    var lastCommittedID: String?  // local HEAD
    var currentBranchID: String?

    static func empty(projectID: String) -> ProjectSyncState {
        ProjectSyncState(
            projectID: projectID,
            localPath: "",
            lastPulledVersionID: nil,
            lastCommittedID: nil,
            currentBranchID: nil
        )
    }
}
