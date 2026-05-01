//
//  WorkingTreeError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

enum WorkingTreeError: LocalizedError {
    case backupFailed(Error)
    case backupAndRestoreFailed(backupError: Error, restoreError: Error)
    case checkoutAndRestoreFailed(checkoutError: Error, restoreError: Error)

    var errorDescription: String? {
        switch self {
        case .backupFailed:
            return "Working tree backup failed."
        case .backupAndRestoreFailed:
            return "Working tree backup failed, and the attempted restore also failed."
        case .checkoutAndRestoreFailed:
            return "Working tree checkout failed, and the attempted restore also failed."
        }
    }

    var failureReason: String? {
        switch self {
        case let .backupFailed(error):
            return error.localizedDescription
        case let .backupAndRestoreFailed(backupError, restoreError):
            return "Backup error: \(backupError.localizedDescription) Restore error: \(restoreError.localizedDescription)"
        case let .checkoutAndRestoreFailed(checkoutError, restoreError):
            return "Checkout error: \(checkoutError.localizedDescription) Restore error: \(restoreError.localizedDescription)"
        }
    }
}
