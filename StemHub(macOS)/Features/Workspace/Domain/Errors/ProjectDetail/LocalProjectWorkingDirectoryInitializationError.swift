//
//  LocalProjectWorkingDirectoryInitializationError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

enum LocalProjectWorkingDirectoryInitializationError: LocalizedError {
    case destinationAlreadyExists(URL)
    case cleanupFailed(initializationError: Error, cleanupError: Error)

    var errorDescription: String? {
        switch self {
        case let .destinationAlreadyExists(url):
            return "A project folder already exists at \(url.path)."
        case .cleanupFailed:
            return "Working directory initialization failed, and the partially-created folder could not be removed."
        }
    }

    var failureReason: String? {
        switch self {
        case .destinationAlreadyExists:
            return "Choose another destination folder or remove the existing project folder first."
        case let .cleanupFailed(initializationError, cleanupError):
            return "Initialization error: \(initializationError.localizedDescription) Cleanup error: \(cleanupError.localizedDescription)"
        }
    }
}
