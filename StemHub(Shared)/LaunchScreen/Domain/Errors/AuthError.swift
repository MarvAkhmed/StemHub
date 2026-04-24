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
    case passwordsDoNotMatch
    case missingGoogleConfiguration
    case firebaseBundleIdentifierMismatch(expected: String, configured: String)
    case missingGoogleURLScheme(String)
    case missingKeychainSharing
    case missingGoogleTokens
    case googleSignInCancelled
    case googleSignInKeychainFailure
    case noRootViewController
    case noWindow
    case unknown
    case userNotFound
    case saveFailed
    case networkFailed
    case faliedToLogout
    
    var errorDescription: String? {
        switch self {
        case .missingData:
            return "Missing required user data"
        case .missingCredentials:
            return "Email and password are required"
        case .passwordsDoNotMatch:
            return "Passwords do not match"
        case .missingGoogleConfiguration:
            return "Google Sign-In is not configured correctly in \(PlatformFirebaseConfiguration.fileName)"
        case .firebaseBundleIdentifierMismatch(let expected, let configured):
            return "\(PlatformFirebaseConfiguration.fileName) is configured for \(configured), but the app is running as \(expected)."
        case .missingGoogleURLScheme(let scheme):
            return "Missing Google Sign-In URL scheme: \(scheme)"
        case .missingKeychainSharing:
            return "The macOS app is missing Keychain Sharing, so Google Sign-In cannot store credentials safely."
        case .missingGoogleTokens:
            return "Failed to get Google authentication tokens"
        case .googleSignInCancelled:
            return "Google Sign-In was cancelled"
        case .googleSignInKeychainFailure:
            return "Google Sign-In could not read or write the app keychain."
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
        case .networkFailed:
            return "Network Error! Please check your internet connection and try again."
        case .faliedToLogout:
            return "Failed to logout"
        }
    }
}
