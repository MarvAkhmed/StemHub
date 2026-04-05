//
//  FileCapabilities.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileCapabilities: Codable {
    let isPlayable: Bool
    let requiresRendering: Bool 
    let isProjectFile: Bool
}

extension FileCapabilities {
    static let playable = FileCapabilities(isPlayable: true, requiresRendering: false, isProjectFile: false)
    static let midi = FileCapabilities(isPlayable: false, requiresRendering: true, isProjectFile: false)
    static let project = FileCapabilities(isPlayable: false, requiresRendering: false, isProjectFile: true)
    static let unknown = FileCapabilities(isPlayable: false, requiresRendering: false, isProjectFile: false)
}
