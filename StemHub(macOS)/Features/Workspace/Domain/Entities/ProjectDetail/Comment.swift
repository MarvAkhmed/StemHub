//
//  Comment.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

enum CommentReviewState: String, Codable, CaseIterable, Sendable {
    case open
    case accepted
    case rejected

    var title: String {
        switch self {
        case .open:
            return "Open"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        }
    }
}

struct Comment: Identifiable, Codable, Sendable {
    let id: String
    let projectID: String
    let branchID: String
    let versionID: String
    let fileID: String?
    let filePath: String
    let userID: String
    let timestamp: Double?
    let rangeStart: Double?
    let rangeEnd: Double?
    let text: String
    let createdAt: Date
    var updatedAt: Date?
    var reviewState: CommentReviewState
    var isHiddenFromTimeline: Bool

    init(
        id: String,
        projectID: String,
        branchID: String,
        versionID: String,
        fileID: String? = nil,
        filePath: String,
        userID: String,
        timestamp: Double?,
        rangeStart: Double?,
        rangeEnd: Double?,
        text: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        reviewState: CommentReviewState = .open,
        isHiddenFromTimeline: Bool = false
    ) {
        self.id = id
        self.projectID = projectID
        self.branchID = branchID
        self.versionID = versionID
        self.fileID = fileID
        self.filePath = filePath
        self.userID = userID
        self.timestamp = timestamp
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reviewState = reviewState
        self.isHiddenFromTimeline = isHiddenFromTimeline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        projectID = try container.decode(String.self, forKey: .projectID)
        branchID = try container.decode(String.self, forKey: .branchID)
        versionID = try container.decode(String.self, forKey: .versionID)
        fileID = try container.decodeIfPresent(String.self, forKey: .fileID)
        filePath = try container.decode(String.self, forKey: .filePath)
        userID = try container.decode(String.self, forKey: .userID)
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp)
        rangeStart = try container.decodeIfPresent(Double.self, forKey: .rangeStart)
        rangeEnd = try container.decodeIfPresent(Double.self, forKey: .rangeEnd)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        reviewState = try container.decodeIfPresent(CommentReviewState.self, forKey: .reviewState) ?? .open
        isHiddenFromTimeline = try container.decodeIfPresent(Bool.self, forKey: .isHiddenFromTimeline) ?? false
    }
}
