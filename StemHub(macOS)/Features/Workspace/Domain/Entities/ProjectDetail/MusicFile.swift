//
//  MusicFile.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct MusicFile: Identifiable, Codable {
    let id: String
    let projectID: String
    var name: String
    var fileExtension: String
    var path: String
    var capabilities: FileCapabilities
    var currentVersionID: String
    var availableFormats: [String]
    let createdAt: Date
}
