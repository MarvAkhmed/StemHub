//
//  AuthService.swift
//  StemHub
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseAuth
import Combine

protocol AuthServiceProtocol: AnyObject {
    var currentUser: User? { get }
    var isSignedIn: Bool { get }
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
    var isSignedInPublisher: AnyPublisher<Bool, Never> { get }
    
    func signUp(email: String, password: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func resetPassword(email: String) async throws
    func signInWithGoogle() async throws -> User?
    func restoreSession() async throws -> User?
    func logout()
}

final class AuthService: ObservableObject, AuthServiceProtocol {
    
    // MARK: - Published state
    @Published private(set) var currentUser: User?
    @Published private(set) var isSignedIn = false
    
    var currentUserPublisher: AnyPublisher<User?, Never> { $currentUser.eraseToAnyPublisher() }
    var isSignedInPublisher: AnyPublisher<Bool, Never> { $isSignedIn.eraseToAnyPublisher() }
    
    // MARK: - Dependencies
    private let emailProvider: EmailAuthProvider
    private let googleProvider: GoogleSignInProvider
    private let sessionManager: any SessionManagement
    private let userRepository: UserFetching & UserSaving
    private let userCreation: UserCreation
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(emailProvider: EmailAuthProvider = FirebaseEmailAuthProvider(),
         googleProvider: GoogleSignInProvider = FirebaseGoogleAuthProvider(),
         sessionManager: (any SessionManagement)? = nil,
         userRepository: UserFetching & UserSaving = FirebaseUserRepository(),
         userCreation: UserCreation = DefaultUserCreationStrategy()) {
        
        self.emailProvider = emailProvider
        self.googleProvider = googleProvider
        self.userRepository = userRepository
        self.userCreation = userCreation
        
        let sm = sessionManager ?? SessionManager(userRepository: userRepository)
        self.sessionManager = sm
        
        (sm as? SessionManager)?.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.currentUser = self.sessionManager.currentUser
                    self.isSignedIn = self.sessionManager.isSignedIn
                }
            }
            .store(in: &cancellables)
        
        Task { @MainActor in
            self.currentUser = sm.currentUser
            self.isSignedIn = sm.isSignedIn
        }
    }

    
    // MARK: - EmailAuthProvider
    func signUp(email: String, password: String) async throws -> User {
        let authResult = try await emailProvider.signUp(email: email, password: password)
        let user = try await userCreation.createUser(from: authResult, name: nil)
        try await userRepository.saveUser(user)
        _ = try await sessionManager.restoreSession()
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let authResult = try await emailProvider.signIn(email: email, password: password)
        let user = try await fetchOrCreateUser(from: authResult)
        _ = try await sessionManager.restoreSession()
        return user
    }
    
    func resetPassword(email: String) async throws {
        try await emailProvider.resetPassword(email: email)
    }
    
    // MARK: - GoogleSignInProvider
    func signInWithGoogle() async throws -> User? {
        let authResult = try await googleProvider.signInWithGoogle()
        let user = try await fetchOrCreateUser(from: authResult)
        _ = try await sessionManager.restoreSession()
        return user
    }
    
    // MARK: - SessionManagement
    func restoreSession() async throws -> User? {
        return try await sessionManager.restoreSession()
    }
    
    func logout() {
        sessionManager.logout()
    }
    
    // MARK: - Private Helpers
    private func fetchOrCreateUser(from authResult: AuthDataResult) async throws -> User {
        if let existingUser = try await userRepository.fetchUser(userId: authResult.user.uid) {
            return existingUser
        }
        let newUser = try await userCreation.createUser(
            from: authResult,
            name: authResult.user.displayName
        )
        try await userRepository.saveUser(newUser)
        return newUser
    }
}
