//
//  Band.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct Band: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var adminUserID: String
    var adminUserIDs: [String]
    var memberIDs: [String]
    var projectIDs: [String]
    let createdAt: Date

    init(
        id: String,
        name: String,
        adminUserID: String,
        adminUserIDs: [String],
        memberIDs: [String],
        projectIDs: [String],
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.adminUserID = adminUserID
        self.adminUserIDs = adminUserIDs
        self.memberIDs = memberIDs
        self.projectIDs = projectIDs
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        memberIDs = try container.decodeIfPresent([String].self, forKey: .memberIDs) ?? []
        projectIDs = try container.decodeIfPresent([String].self, forKey: .projectIDs) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        adminUserID = try container.decodeIfPresent(String.self, forKey: .adminUserID) ?? memberIDs.first ?? ""
        adminUserIDs = try container.decodeIfPresent([String].self, forKey: .adminUserIDs) ?? [adminUserID]
    }

    var hasAdmin: Bool {
        !allAdminUserIDs.isEmpty
    }

    var allAdminUserIDs: [String] {
        NSOrderedSet(array: adminUserIDs + [adminUserID]).array.compactMap { $0 as? String }
    }

    func isAdmin(userID: String) -> Bool {
        allAdminUserIDs.contains(userID)
    }
}
