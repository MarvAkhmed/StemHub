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
        return "Failed to send password reset email"
    }
}
