//
//  AuthenticationViewModelProtocol.swift
//  StemHub
//

import Foundation
import FirebaseAuth
import SwiftUI
import Combine
import FirebaseFirestore

protocol AuthViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var alertItem: AlertItem? { get set }
    var isAuthenticated: Bool { get set }
    var currentUser: User? { get }
    var isLoadingMessage: String { get }
    
    func signUp(email: String, password: String, confirmPassword: String) async
    func signIn(email: String, password: String) async
    
    func signInWithDrive() async throws -> User?
    func resetPassword(for user: User) async
}

final class AuthViewModel: AuthViewModelProtocol {

    
    @Published var isLoading: Bool = false
    @Published var isLoadingMessage: String = "Loading..."
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var alertItem: AlertItem? = nil
  
    private var cancellables = Set<AnyCancellable>()
    private let googleService = GoogleAuthService.shared
    init() {
        googleService.$isSignedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSignedIn in
                self?.isAuthenticated = isSignedIn
                if isSignedIn {
                    self?.currentUser = self?.googleService.currentUser
                }
            }
            .store(in: &cancellables)
        
        Task { @MainActor in
            await restoreSession()
        }
    }

    @MainActor
    private func restoreSession() async {
        await MainActor.run {
            isLoading = true
            isLoadingMessage = "Restoring your session..."
        }
        do {
            if  let user = try? await googleService.restoreSession() {
                self.currentUser = user
                self.isAuthenticated = true
            } else {
                self.isAuthenticated = false
            }
        }
        await MainActor.run {
            isLoading = false
        }
    }
//    func signUp(email: String, password: String, confirmPassword: String) async {
//        
//        await MainActor.run {
//            isLoading = true
//            isLoadingMessage = "Creating your account..."
//        }
//        
//        defer {
//            Task { @MainActor in
//                self.isLoading = false
//            }
//        }
//        
//        do {
//            try validate(email: email, password: password, confirmPassword: confirmPassword)
//            
//            let tempUser = User(
//                id: UUID().uuidString,
//                name: nil,
//                email: email,
//                password: password
//            )
//            
//           _ = try await googleService.signUp(with: tempUser)
//            
//            showAlert(title: "Success", message: "Account created successfully!")
//            isAuthenticated = true
//        } catch {
//            handleError(error)
//        }
//    }
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            isLoadingMessage = "Signing you in..."
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        do {
            try validate(email: email, password: password)
            let user = User(
                id: UUID().uuidString,
                name: nil,
                email: email,
                password: password
            )
           _ = try await googleService.signIn(with: user)
            self.isAuthenticated = true
        } catch {
            print("can't login")
        }
    }
    
    // AuthViewModel.swift - Update signUp method

    func signUp(email: String, password: String, confirmPassword: String) async {
        await MainActor.run {
            isLoading = true
            isLoadingMessage = "Creating your account..."
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        do {
            try validate(email: email, password: password, confirmPassword: confirmPassword)
            
            print("🚀 Starting sign up process...")
            
            let tempUser = User(
                id: UUID().uuidString,
                name: nil,
                email: email,
                password: password,
                bandIDs: []
            )
            
            let createdUser = try await googleService.signUp(with: tempUser)
            print("✅ Sign up completed for user: \(createdUser.id)")
            
            // Verify user was created in Firestore
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(createdUser.id).getDocument()
            if userDoc.exists {
                print("✅ Verified: User document exists in Firestore")
            } else {
                print("❌ ERROR: User document NOT found in Firestore!")
            }
            
            showAlert(title: "Success", message: "Account created successfully!")
            isAuthenticated = true
        } catch {
            print("❌ Sign up error: \(error)")
            handleError(error)
        }
    }
    
    func signInWithDrive() async throws -> User? {
        await MainActor.run {
            isLoading = true
            isLoadingMessage = "Connecting to Google..."
        }
        defer { Task { @MainActor in self.isLoading = false } }
        
        do {
            let user = try await googleService.signInWithGoogle()
            self.isAuthenticated = true
            await MainActor.run {
                showAlert(title: "Success", message: "Logged in as \(user?.email ?? "User")!")
                self.isAuthenticated = true
            }
            return user
        } catch {
            await MainActor.run {
                handleError(error)
            }
            return nil
        }
      
    }
    // MARK: - Validation
    private func validate(email: String, password: String, confirmPassword: String) throws {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            throw AuthError.missingData
        }
        
        guard password == confirmPassword else {
            throw AuthError.passwordsDoNotMatch
        }
    }
    
    private func validate(email: String, password: String) throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.missingData
        }
    }
    
    // MARK: - Central Error Handler
    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            showAlert(title: "Error", message: authError.localizedDescription)
            return
        }
        
        let nsError = error as NSError
        var message = error.localizedDescription
        
        if let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .emailAlreadyInUse:
                message = "An account already exists with this email."
            case .invalidEmail:
                message = "Invalid email format."
            case .weakPassword:
                message = "Password should be at least 6 characters."
            default:
                break
            }
        }

        showAlert(title: "Error", message: message)
    }
    
    func resetPassword(for user: User) async {
        await MainActor.run {
            isLoading = true
            isLoadingMessage = "Sending reset email..."
        }

        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        do {
            try await googleService.resetPassword(for: user)
            showAlert(title: "Success", message: "Password reset email sent successfully!")
        } catch {
            handleError(error)
        }
    }
    func logout() {
        googleService.logout()
        isAuthenticated = false
        currentUser = nil
    }
    // MARK: - Alert
    private func showAlert(title: String, message: String) {
        Task { @MainActor in
            self.alertItem = AlertItem(title: title, message: message)
        }
    }
}
