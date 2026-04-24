//
//  ProjectDetailSection.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum ProjectDetailSection: String, CaseIterable, Identifiable {
    case workspace
    case comments
    case changes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace:
            return "Workspace"
        case .comments:
            return "Comments"
        case .changes:
            return "Changes"
        }
    }

    var systemImage: String {
        switch self {
        case .workspace:
            return "rectangle.split.3x1"
        case .comments:
            return "text.bubble"
        case .changes:
            return "arrow.trianglehead.branch"
        }
    }
}
