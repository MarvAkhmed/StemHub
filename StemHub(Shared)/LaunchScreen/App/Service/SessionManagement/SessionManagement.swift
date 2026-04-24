//
//  SessionManagement.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import Combine

protocol AuthenticatedUserProviding: AnyObject {
    var currentUser: User? { get }
}

protocol AuthSessionStateProviding: AuthenticatedUserProviding {
    var isSignedIn: Bool { get }
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
    var isSignedInPublisher: AnyPublisher<Bool, Never> { get }
}

protocol SessionActivating {
    func activateSession(with user: User) async
}

protocol SessionRestoring {
    func restoreSession() async throws -> User?
}

protocol SessionLoggingOut {
    func logout()
}

typealias SessionManagement = AuthSessionStateProviding &
                              SessionActivating &
                              SessionRestoring &
                              SessionLoggingOut


final class SessionManager: SessionManagement {
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isSignedIn = false
    
    var currentUserPublisher: AnyPublisher<User?, Never> { $currentUser.eraseToAnyPublisher() }
    var isSignedInPublisher: AnyPublisher<Bool, Never> { $isSignedIn.eraseToAnyPublisher() }
    
    private let userRepository: AuthUserRepository
    private let userDefaultsManager: UserDefaultsManaging
    private let authStateProvider: AuthStateProviding
    
    private var listenerHandle: AuthStateListenerHandle?
    
    init(
        userRepository: AuthUserRepository,
        userDefaultsManager: UserDefaultsManaging,
        authStateProvider: AuthStateProviding,
    ) {
        self.userRepository = userRepository
        self.userDefaultsManager = userDefaultsManager
        self.authStateProvider = authStateProvider
        setupAuthStateListener()
    }
    
    deinit {
        if let listenerHandle {
            authStateProvider.removeStateListener(listenerHandle)
        }
    }
    
    func restoreSession() async throws -> User? {
        if let userId = authStateProvider.currentUserID {
            if let existingUser = try await userRepository.fetchUser(userId: userId) {
                try Task.checkCancellation()
                updateCurrentUser(existingUser)
                return existingUser
            }
        }
        
        if let savedUser = userDefaultsManager.loadUser() {
            try Task.checkCancellation()
            updateCurrentUser(savedUser)
            return savedUser
        }
        return nil
    }
    
    func activateSession(with user: User) async {
        updateCurrentUser(user)
    }
    
    func logout() {
        clearCurrentUser()
        userDefaultsManager.clearUser()
    }
    
}

private extension SessionManager {
    func setupAuthStateListener() {
        listenerHandle = authStateProvider.addStateListener { [weak self] state in
            if case .signedOut = state {
                Task { @MainActor [weak self] in
                    self?.logout()
                }
            }
        }
    }
    
    func updateCurrentUser(_ user: User?) {
        currentUser = user
        isSignedIn = user != nil
        if let user = user {
            userDefaultsManager.saveUser(user)
        }
    }
    
    func clearCurrentUser() {
        currentUser = nil
        isSignedIn = false
    }
}
