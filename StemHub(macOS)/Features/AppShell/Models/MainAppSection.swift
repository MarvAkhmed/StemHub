//
//  MainAppSection.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum MainAppSection: String, CaseIterable, Identifiable {
    case workspace
    case inbox
    case profile
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace:
            return "Workspace"
        case .inbox:
            return "Inbox"
        case .profile:
            return "Profile"
        case .settings:
            return "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .workspace:
            return "Projects, branches, and review sessions"
        case .inbox:
            return "Band invites and collaboration updates"
        case .profile:
            return "Bands, releases, and artist identity"
        case .settings:
            return "Studio preferences and account controls"
        }
    }

    var systemImage: String {
        switch self {
        case .workspace:
            return "square.grid.2x2.fill"
        case .inbox:
            return "bell.badge.fill"
        case .profile:
            return "person.crop.circle.fill"
        case .settings:
            return "slider.horizontal.3"
        }
    }
}
