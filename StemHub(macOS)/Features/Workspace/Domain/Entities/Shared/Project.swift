//
//  Project.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct Project: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var posterURL: String?
    var bandID: String
    var createdBy: String
    var currentBranchID: String     // Current branch
    var currentVersionID: String    // HEAD of that branch
    let createdAt: Date
    let updatedAt: Date
    var posterBase64: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}
