
//
//  GoogleAuthService.swift
//  StemHub
//
//  Created by Marwa Awad on 28.03.2026.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

protocol GoogleServiceProtocol: ObservableObject {
    func signUp(with user: User) async throws -> User
    func signIn(with user: User) async throws -> User
    func signInWithGoogle() async throws -> User?
    func restoreSession() async throws -> User?
    func resetPassword(for user: User) async throws
    func logout()
}

final class GoogleAuthService: GoogleServiceProtocol {
    
    private var authOrchestrator: UserAuthOrchestrator!
    
    // MARK: - Singleton
    static let shared = GoogleAuthService()
    private init() {
        setupStrategies()
    }
    
    // MARK: - Properties
    @Published var isSignedIn = false
    @Published var currentUser: User? {
        didSet {
            UserDefaultsManager.saveUser(currentUser)
        }
    }
    
    private func setupStrategies() {
        let fetchStrategy = FirestoreFetchStrategy()
        let saveStrategy = FirestoreSaveStrategy()
        let creationStrategy = DefaultUserCreationStrategy()
        let stateStrategy = DefaultAuthStateStrategy()
        
        self.authOrchestrator = UserAuthOrchestrator(
            fetchStrategy: fetchStrategy,
            saveStrategy: saveStrategy,
            creationStrategy: creationStrategy,
            stateStrategy: stateStrategy,
            authService: self
        )
    }
    
    // MARK: - Sign Up
    func signUp(with user: User) async throws -> User {
        guard let email = user.email,
              let password = user.password else {
            throw AuthError.missingData
        }
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let newUser = try await authOrchestrator.processUserAfterAuth(
            authResult: result,
            email: email,
            name: user.name
        )
        
        return newUser
    }
    
    // MARK: - Sign In
    func signIn(with user: User) async throws -> User {
        guard let email = user.email,
              let password = user.password,
              !email.isEmpty,
              !password.isEmpty else {
            throw AuthError.missingCredentials
        }
        
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        
        // Use strategy pattern
        let signedInUser = try await authOrchestrator.processUserAfterAuth(
            authResult: result,
            email: email,
            name: user.name
        )
        
        return signedInUser
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async throws -> User? {
#if os(iOS)
        return try await driveForiOS()
#elseif os(macOS)
        return try await driveForMacOS()
#endif
    }
    
    // MARK: - Restore session
    func restoreSession() async throws -> User? {
        if let firebaseUser = Auth.auth().currentUser {
            // Use strategy pattern to fetch user
            let fetchStrategy = FirestoreFetchStrategy()
            if let existingUser = try await fetchStrategy.fetch(userId: firebaseUser.uid) {
                await MainActor.run {
                    self.currentUser = existingUser
                    self.isSignedIn = true
                }
                return existingUser
            } else {
                // Create minimal user if doesn't exist
                let restoredUser = User(
                    id: firebaseUser.uid,
                    name: firebaseUser.displayName,
                    email: firebaseUser.email,
                    password: nil,
                    bandIDs: []
                )
                let saveStrategy = FirestoreSaveStrategy()
                try await saveStrategy.save(restoredUser)
                
                await MainActor.run {
                    self.currentUser = restoredUser
                    self.isSignedIn = true
                }
                return restoredUser
            }
        } else if let savedUser = UserDefaultsManager.loadUser() {
            await MainActor.run {
                self.currentUser = savedUser
                self.isSignedIn = true
            }
            return savedUser
        } else {
            throw NSError(domain: "No active session", code: -1)
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(for user: User) async throws {
        guard let email = user.email, !email.isEmpty else {
            throw NSError(domain: "Email empty", code: -1)
        }
        
        do {
            let settings = ActionCodeSettings()
            settings.url = URL(string: "https://stemhub-b2c24.web.app/reset-password.html")!
            settings.handleCodeInApp = true
            
            try await Auth.auth().sendPasswordReset(withEmail: email, actionCodeSettings: settings)
        } catch {
            throw ResetPasswordError.failed
        }
    }
    
    // MARK: - Logout
    func logout() {
        try? Auth.auth().signOut()
        isSignedIn = false
        currentUser = nil
        UserDefaultsManager.clearUser()
    }
    
    private func driveForiOS() async throws -> User? {
#if os(iOS)
        return try await withCheckedThrowingContinuation { continuation in
            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
                continuation.resume(throwing: NSError(domain: "No root VC", code: -1))
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let googleUser = result?.user,
                      let idToken = googleUser.idToken?.tokenString else {
                    continuation.resume(throwing: NSError(domain: "Tokens missing", code: -1))
                    return
                }
                
                let accessToken = googleUser.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                
                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let authResult = authResult else {
                        continuation.resume(throwing: NSError(domain: "Auth failed", code: -1))
                        return
                    }
                    
                    Task {
                        do {
                            // Use the actual authResult from Firebase
                            let user = try await self?.authOrchestrator.processUserAfterAuth(
                                authResult: authResult,  // ← Pass the actual AuthDataResult
                                email: authResult.user.email ?? "",
                                name: authResult.user.displayName
                            )
                            continuation.resume(returning: user)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
#elseif os(macOS)
        return nil
#endif
    }
    
    private func driveForMacOS() async throws -> User? {
#if os(macOS)
        return try await withCheckedThrowingContinuation { continuation in
            guard let window = NSApplication.shared.windows.first else {
                continuation.resume(throwing: NSError(domain: "No NSWindow", code: -1))
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: window) { [weak self] result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let googleUser = result?.user,
                      let idToken = googleUser.idToken?.tokenString else {
                    continuation.resume(throwing: NSError(domain: "No Google user", code: -1))
                    return
                }
                
                let accessToken = googleUser.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let authResult = authResult else {
                        continuation.resume(throwing: NSError(domain: "Firebase auth failed", code: -1))
                        return
                    }
                    
                    Task {
                        do {
                            // Use the actual authResult from Firebase
                            let user = try await self?.authOrchestrator.processUserAfterAuth(
                                authResult: authResult,
                                email: authResult.user.email ?? "",
                                name: authResult.user.displayName
                            )
                            continuation.resume(returning: user)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
#elseif os(iOS)
        return nil
#endif
    }
}
