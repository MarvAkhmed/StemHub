//
//  AuthService.swift
//  StemHub
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import Combine

protocol CredentialAuthenticating {
    func signUp(email: String, password: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func resetPassword(email: String) async throws
    func signInWithGoogle() async throws -> User?
}

protocol AuthServiceProtocol:
    AuthSessionStateProviding,
    CredentialAuthenticating,
    SessionRestoring,
    SessionLoggingOut {}

final class AuthService: AuthServiceProtocol {

    // MARK: - Single source of truth
    var currentUser: User? { sessionManager.currentUser }
    var isSignedIn: Bool { sessionManager.isSignedIn }
    var currentUserPublisher: AnyPublisher<User?, AuthError> { sessionManager.currentUserPublisher }
    var isSignedInPublisher: AnyPublisher<Bool, AuthError> { sessionManager.isSignedInPublisher }

    // MARK: - Dependencies
    private let emailProvider: EmailAuthenticating
    private let googleProvider: GoogleAuth
    private let sessionManager: any SessionManagement
    private let userRepository: AuthUserRepository
    
    // MARK: - Init
    init(
        emailProvider: EmailAuthenticating,
        googleProvider: GoogleAuth,
        sessionManager: any SessionManagement,
        userRepository: AuthUserRepository
    ) {
        self.emailProvider = emailProvider
        self.googleProvider = googleProvider
        self.sessionManager = sessionManager
        self.userRepository = userRepository
    }

    
    // MARK: - EmailAuthProvider
    func signUp(email: String, password: String) async throws -> User {
        let authenticatedUser = try await emailProvider.signUp(email: email, password: password)
        return try await resolveAndActivateSession(from: authenticatedUser)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let authenticatedUser = try await emailProvider.signIn(email: email, password: password)
        return try await resolveAndActivateSession(from: authenticatedUser)
    }
    
    func resetPassword(email: String) async throws {
        try await emailProvider.resetPassword(email: email)
    }
    
    // MARK: - GoogleSignInProvider
    func signInWithGoogle() async throws -> User? {
        let authenticatedUser = try await googleProvider.signInWithGoogle()
        return try await resolveAndActivateSession(from: authenticatedUser)
    }
    
    // MARK: - SessionManagement
    func restoreSession() async throws -> User? {
        return try await sessionManager.restoreSession()
    }
    
    func logout() {
        try? googleProvider.signOut()
        if let signingOutProvider = emailProvider as? any AuthProviderSigningOut {
            try? signingOutProvider.signOut()
        }
        sessionManager.logout()
    }
    
    // MARK: - Private Helpers
    private func resolveAndActivateSession(from authenticatedUser: User) async throws -> User {
        let user = try await resolveExistingOrCreateUser(from: authenticatedUser)
        await sessionManager.activateSession(with: user)
        return user
    }

    private func resolveExistingOrCreateUser(from authenticatedUser: User) async throws -> User {
        if let existingUser = try await userRepository.fetchUser(userId: authenticatedUser.id) {
            return existingUser
        }

        try await userRepository.saveUser(authenticatedUser)
        return authenticatedUser
    }
}
