//
//  EmailAuthenticating.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//


import Foundation

protocol EmailAuthenticating {
    func signUp(email: String, password: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func resetPassword(email: String) async throws
}

protocol AuthProviderSigningOut {
    func signOut() throws
}

typealias EmailAuthenticator = EmailAuthenticating & AuthProviderSigningOut
