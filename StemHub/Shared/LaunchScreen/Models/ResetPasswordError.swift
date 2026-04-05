//
//  ResetPasswordError.swift
//  StemHub
//
//  Created by Marwa Awad on 31.03.2026.
//

import Foundation

enum ResetPasswordError: LocalizedError {
    case failed
    
    var errorDescription: String? {
        switch self {
        case .failed:
            return "Password reset failed. Please try again."
        }
    }
}

enum AuthError: LocalizedError {
    case missingData
    case missingCredentials
    case passwordsDoNotMatch
    var errorDescription: String? {
        switch self {
        case .missingData:
            return "Please fill in all required fields."
        case .missingCredentials:
            return  "Missing credentials"
        case .passwordsDoNotMatch:
            return "make sure the passwords match."
        }
    }
}
