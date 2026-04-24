//
//  ProjectSyncState.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

struct ProjectSyncState: Codable, Sendable {
    let projectID: String
    var localPath: String
    var lastPulledVersionID: String? // remote HEAD
    var lastCommittedID: String?  // local HEAD
    var currentBranchID: String?

    nonisolated init(
        projectID: String,
        localPath: String = "",
        lastPulledVersionID: String? = nil,
        lastCommittedID: String? = nil,
        currentBranchID: String? = nil
    ) {
        self.projectID = projectID
        self.localPath = localPath
        self.lastPulledVersionID = lastPulledVersionID
        self.lastCommittedID = lastCommittedID
        self.currentBranchID = currentBranchID
    }

    nonisolated static func empty(projectID: String) -> ProjectSyncState {
        ProjectSyncState(
            projectID: projectID,
            localPath: "",
            lastPulledVersionID: nil,
            lastCommittedID: nil,
            currentBranchID: nil
        )
    }
}

extension ProjectSyncState {
    private enum CodingKeys: String, CodingKey {
        case projectID
        case localPath
        case lastPulledVersionID
        case lastCommittedID
        case currentBranchID
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectID = try container.decode(String.self, forKey: .projectID)
        localPath = try container.decode(String.self, forKey: .localPath)
        lastPulledVersionID = try container.decodeIfPresent(String.self, forKey: .lastPulledVersionID)
        lastCommittedID = try container.decodeIfPresent(String.self, forKey: .lastCommittedID)
        currentBranchID = try container.decodeIfPresent(String.self, forKey: .currentBranchID)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectID, forKey: .projectID)
        try container.encode(localPath, forKey: .localPath)
        try container.encodeIfPresent(lastPulledVersionID, forKey: .lastPulledVersionID)
        try container.encodeIfPresent(lastCommittedID, forKey: .lastCommittedID)
        try container.encodeIfPresent(currentBranchID, forKey: .currentBranchID)
    }
}
