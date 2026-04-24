//
//  WorkspaceActivityState.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum WorkspaceActivityState: Equatable {
    case idle
    case loading(message: String)
    case creating(message: String)
    case deleting(message: String)

    var isLoading: Bool {
        switch self {
        case .idle:
            return false
        case .loading, .creating, .deleting:
            return true
        }
    }

    var isCreatingProject: Bool {
        if case .creating = self {
            return true
        }

        return false
    }

    var overlayMessage: String? {
        switch self {
        case .creating(let message), .deleting(let message):
            return message
        case .idle, .loading:
            return nil
        }
    }
}
