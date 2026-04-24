//
//  AuthActivityState.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum AuthActivityState: Equatable {
    case idle
    case restoringSession
    case processing(String)

    var isLoading: Bool {
        switch self {
        case .idle:
            return false
        case .restoringSession, .processing:
            return true
        }
    }

    var message: String {
        switch self {
        case .idle:
            return "Loading..."
        case .restoringSession:
            return "Restoring your session..."
        case .processing(let message):
            return message
        }
    }

    var blocksUserInitiatedActions: Bool {
        if case .processing = self {
            return true
        }

        return false
    }
}
