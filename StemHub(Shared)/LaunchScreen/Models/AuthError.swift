//
//  AuthError.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum AuthError: LocalizedError {
    case missingData
    case missingCredentials
    case missingGoogleTokens
    case noRootViewController
    case noWindow
    case unknown
    case userNotFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .missingData:
            return "Missing required user data"
        case .missingCredentials:
            return "Email and password are required"
        case .missingGoogleTokens:
            return "Failed to get Google authentication tokens"
        case .noRootViewController:
            return "Cannot find root view controller"
        case .noWindow:
            return "Cannot find application window"
        case .unknown:
            return "An unknown error occurred"
        case .userNotFound:
            return "User not found in database"
        case .saveFailed:
            return "Failed to save user data"
        }
    }
}
