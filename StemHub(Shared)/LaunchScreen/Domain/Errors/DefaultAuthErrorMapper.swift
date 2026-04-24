//
//  DefaultAuthErrorMapper.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//


import Foundation
import FirebaseAuth

protocol AuthErrorMapping {
    func message(for error: Error) -> String
}

struct DefaultAuthErrorMapper: AuthErrorMapping {
    func message(for error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }

        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch code {
        case .emailAlreadyInUse:
            return "An account already exists with this email."
        case .invalidEmail:
            return "Invalid email format."
        case .keychainError:
            return "Google Sign-In could not access the keychain. The macOS target must be signed with Keychain Sharing enabled."
        case .weakPassword:
            return "Password should be at least 6 characters."
        default:
            return error.localizedDescription
        }
    }
}
