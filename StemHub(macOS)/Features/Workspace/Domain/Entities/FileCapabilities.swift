//
//  FileCapabilities.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileCapabilities: Codable, Sendable {
    let isPlayable: Bool
    let requiresRendering: Bool 
    let isProjectFile: Bool
}

extension FileCapabilities {
    nonisolated static let playable = FileCapabilities(isPlayable: true, requiresRendering: false, isProjectFile: false)
    nonisolated static let midi = FileCapabilities(isPlayable: false, requiresRendering: true, isProjectFile: false)
    nonisolated static let project = FileCapabilities(isPlayable: false, requiresRendering: false, isProjectFile: true)
    nonisolated static let unknown = FileCapabilities(isPlayable: false, requiresRendering: false, isProjectFile: false)
}
