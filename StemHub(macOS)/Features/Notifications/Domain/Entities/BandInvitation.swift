//
//  BandInvitation.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum BandInvitationStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case accepted
    case declined

    var title: String {
        rawValue.capitalized
    }
}

struct BandInvitation: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let bandID: String
    let bandName: String
    let inviteeUserID: String
    let inviteeEmail: String
    let requestedByUserID: String
    let requestedByName: String?
    var status: BandInvitationStatus
    let createdAt: Date
    var respondedAt: Date?

    init(
        id: String,
        bandID: String,
        bandName: String,
        inviteeUserID: String,
        inviteeEmail: String,
        requestedByUserID: String,
        requestedByName: String?,
        status: BandInvitationStatus,
        createdAt: Date,
        respondedAt: Date?
    ) {
        self.id = id
        self.bandID = bandID
        self.bandName = bandName
        self.inviteeUserID = inviteeUserID
        self.inviteeEmail = inviteeEmail
        self.requestedByUserID = requestedByUserID
        self.requestedByName = requestedByName
        self.status = status
        self.createdAt = createdAt
        self.respondedAt = respondedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        bandID = try container.decode(String.self, forKey: .bandID)
        bandName = try container.decodeIfPresent(String.self, forKey: .bandName) ?? "Band"
        inviteeUserID = try container.decode(String.self, forKey: .inviteeUserID)
        inviteeEmail = try container.decodeIfPresent(String.self, forKey: .inviteeEmail) ?? ""
        requestedByUserID = try container.decode(String.self, forKey: .requestedByUserID)
        requestedByName = try container.decodeIfPresent(String.self, forKey: .requestedByName)
        status = try container.decodeIfPresent(BandInvitationStatus.self, forKey: .status) ?? .pending
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        respondedAt = try container.decodeIfPresent(Date.self, forKey: .respondedAt)
    }
}
