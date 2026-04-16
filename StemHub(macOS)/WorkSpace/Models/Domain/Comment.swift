//
//  Comment.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let fileID: String
    let versionID: String
    let userID: String
    let timestamp: Double?
    let rangeStart: Double?
    let rangeEnd: Double?
    let text: String
    let createdAt: Date
}
