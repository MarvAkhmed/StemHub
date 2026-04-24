//
//  AuthFormValidator.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

struct AuthFormValidator: AuthFormValidating {
    func validateSignUp(email: String, password: String, confirmPassword: String) throws {
        try validateCredentials(email: email, password: password)

        guard password == confirmPassword else {
            throw AuthError.passwordsDoNotMatch
        }
    }

    func validateSignIn(email: String, password: String) throws {
        try validateCredentials(email: email, password: password)
    }

    func validateResetPassword(email: String) throws {
        guard email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw AuthError.missingCredentials
        }
    }

    private func validateCredentials(email: String, password: String) throws {
        guard email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              password.isEmpty == false else {
            throw AuthError.missingCredentials
        }
    }
}
