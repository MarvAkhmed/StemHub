//
//  IOSWorkspaceSnapshot.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct IOSWorkspaceSnapshot: Sendable {
    let bands: [IOSBandSummary]
    let projects: [IOSProjectSummary]
}

struct IOSBandSummary: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var adminUserID: String
    var memberIDs: [String]
    var projectIDs: [String]
    let createdAt: Date

    init(
        id: String,
        name: String,
        adminUserID: String,
        memberIDs: [String],
        projectIDs: [String],
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.adminUserID = adminUserID
        self.memberIDs = memberIDs
        self.projectIDs = projectIDs
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Band"
        memberIDs = try container.decodeIfPresent([String].self, forKey: .memberIDs) ?? []
        projectIDs = try container.decodeIfPresent([String].self, forKey: .projectIDs) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        adminUserID = try container.decodeIfPresent(String.self, forKey: .adminUserID) ?? memberIDs.first ?? ""
    }

    var memberCountLabel: String {
        "\(memberIDs.count) member\(memberIDs.count == 1 ? "" : "s")"
    }

    var projectCountLabel: String {
        "\(projectIDs.count) project\(projectIDs.count == 1 ? "" : "s")"
    }
}

struct IOSProjectSummary: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var bandID: String
    var createdBy: String
    var currentBranchID: String
    var currentVersionID: String
    let createdAt: Date
    let updatedAt: Date
    var posterBase64: String?

    init(
        id: String,
        name: String,
        bandID: String,
        createdBy: String,
        currentBranchID: String,
        currentVersionID: String,
        createdAt: Date,
        updatedAt: Date,
        posterBase64: String?
    ) {
        self.id = id
        self.name = name
        self.bandID = bandID
        self.createdBy = createdBy
        self.currentBranchID = currentBranchID
        self.currentVersionID = currentVersionID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.posterBase64 = posterBase64
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Project"
        bandID = try container.decodeIfPresent(String.self, forKey: .bandID) ?? ""
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
        currentBranchID = try container.decodeIfPresent(String.self, forKey: .currentBranchID) ?? ""
        currentVersionID = try container.decodeIfPresent(String.self, forKey: .currentVersionID) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        posterBase64 = try container.decodeIfPresent(String.self, forKey: .posterBase64)
    }

    var branchLabel: String {
        currentBranchID.isEmpty ? "No branch yet" : "Branch \(currentBranchID.prefix(6))"
    }

    var versionLabel: String {
        currentVersionID.isEmpty ? "No approved version yet" : "Version \(currentVersionID.prefix(6))"
    }
}
