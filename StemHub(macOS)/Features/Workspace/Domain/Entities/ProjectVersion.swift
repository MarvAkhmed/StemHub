//
//  ProjectVersion.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

enum ProjectVersionApprovalState: String, Codable, Sendable {
    case pendingReview
    case approved

    var title: String {
        switch self {
        case .pendingReview:
            return "Pending Admin Approval"
        case .approved:
            return "Approved"
        }
    }
}

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
    var approvalState: ProjectVersionApprovalState
    var approvedByUserID: String?
    var approvedAt: Date?

    init(
        id: String,
        projectID: String,
        versionNumber: Int,
        parentVersionID: String?,
        fileVersionIDs: [String],
        createdBy: String,
        createdAt: Date,
        notes: String?,
        diff: ProjectDiff,
        commitId: String?,
        approvalState: ProjectVersionApprovalState = .pendingReview,
        approvedByUserID: String? = nil,
        approvedAt: Date? = nil
    ) {
        self.id = id
        self.projectID = projectID
        self.versionNumber = versionNumber
        self.parentVersionID = parentVersionID
        self.fileVersionIDs = fileVersionIDs
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.notes = notes
        self.diff = diff
        self.commitId = commitId
        self.approvalState = approvalState
        self.approvedByUserID = approvedByUserID
        self.approvedAt = approvedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        projectID = try container.decode(String.self, forKey: .projectID)
        versionNumber = try container.decode(Int.self, forKey: .versionNumber)
        parentVersionID = try container.decodeIfPresent(String.self, forKey: .parentVersionID)
        fileVersionIDs = try container.decode([String].self, forKey: .fileVersionIDs)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        diff = try container.decode(ProjectDiff.self, forKey: .diff)
        commitId = try container.decodeIfPresent(String.self, forKey: .commitId)
        approvalState = try container.decodeIfPresent(ProjectVersionApprovalState.self, forKey: .approvalState) ?? .pendingReview
        approvedByUserID = try container.decodeIfPresent(String.self, forKey: .approvedByUserID)
        approvedAt = try container.decodeIfPresent(Date.self, forKey: .approvedAt)
    }
}
