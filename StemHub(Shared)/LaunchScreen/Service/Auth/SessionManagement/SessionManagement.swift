//
//  SessionManagement.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import FirebaseAuth
import Foundation
import Combine

protocol SessionManagement: ObservableObject {
    var currentUser: User? { get }
    var isSignedIn: Bool { get }
    func restoreSession() async throws -> User?
    func logout()
}

final class SessionManager: SessionManagement {
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isSignedIn = false
    
    private let userRepository: UserFetching & UserSaving
    private let userDefaultsManager: UserDefaultsManaging
    
    init(userRepository: UserFetching & UserSaving,
         userDefaultsManager: UserDefaultsManaging = UserDefaultsManager.shared) {
        self.userRepository = userRepository
        self.userDefaultsManager = userDefaultsManager
        setupAuthStateListener()
    }
    
    func restoreSession() async throws -> User? {
        if let firebaseUser = Auth.auth().currentUser {
            if let existingUser = try await userRepository.fetchUser(userId: firebaseUser.uid) {
                await updateCurrentUser(existingUser)
                return existingUser
            } else {
                let restoredUser = User(
                    id: firebaseUser.uid,
                    name: firebaseUser.displayName,
                    email: firebaseUser.email,
                    password: nil,
                    bandIDs: []
                )
                try await userRepository.saveUser(restoredUser)
                await updateCurrentUser(restoredUser)
                return restoredUser
            }
        } else if let savedUser = userDefaultsManager.loadUser() {
            await updateCurrentUser(savedUser)
            return savedUser
        }
        return nil
    }
    
    func logout() {
        try? Auth.auth().signOut()
        Task { await clearCurrentUser() }
        userDefaultsManager.clearUser()
    }
    
    private func setupAuthStateListener() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if firebaseUser == nil {
                Task { await self?.clearCurrentUser() }
            }
        }
    }
    
    @MainActor
    private func updateCurrentUser(_ user: User?) async {
        currentUser = user
        isSignedIn = user != nil
        if let user = user {
            userDefaultsManager.saveUser(user)
        }
    }
    
    @MainActor
    private func clearCurrentUser() async{
        currentUser = nil
        isSignedIn = false
    }
}
