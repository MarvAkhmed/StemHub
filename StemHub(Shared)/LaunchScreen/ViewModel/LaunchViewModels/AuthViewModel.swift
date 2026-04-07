//
//  AuthenticationViewModelProtocol.swift
//  StemHub
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

protocol AuthViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var alertItem: AlertItem? { get set }
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    var isLoadingMessage: String { get }
    
    func signUp(email: String, password: String, confirmPassword: String) async
    func signIn(email: String, password: String) async
    func signInWithGoogle() async
    func resetPassword(email: String) async
    func logout()
}

final class AuthViewModel: AuthViewModelProtocol {
    
    private let authService: AuthServiceProtocol
    
    @Published var isLoading = false
    @Published var isLoadingMessage = "Loading..."
    @Published var alertItem: AlertItem?
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
        
        // Subscribe to publishers from auth service
        authService.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        authService.isSignedInPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSignedIn in
                self?.isAuthenticated = isSignedIn
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Public methods
    func signUp(email: String, password: String, confirmPassword: String) async {
        await setLoading(true, message: "Creating your account...")
        defer { Task { await setLoading(false) } }
        
        do {
            try validate(email: email, password: password, confirmPassword: confirmPassword)
            _ = try await authService.signUp(email: email, password: password)
            await showAlert(title: "Success", message: "Account created successfully!")
        } catch {
            await handleError(error)
        }
    }
    
    func signIn(email: String, password: String) async {
        await setLoading(true, message: "Signing you in...")
        defer { Task { await setLoading(false) } }
        
        do {
            try validate(email: email, password: password)
            _ = try await authService.signIn(email: email, password: password)
        } catch {
            await handleError(error)
        }
    }
    
    func signInWithGoogle() async {
        await setLoading(true, message: "Connecting to Google...")
        defer { Task { await setLoading(false) } }
        
        do {
            if let user = try await authService.signInWithGoogle() {
                await showAlert(title: "Success", message: "Logged in as \(user.email ?? "User")!")
            }
        } catch {
            await handleError(error)
        }
    }
    
    func resetPassword(email: String) async {
        await setLoading(true, message: "Sending reset email...")
        defer { Task { await setLoading(false) } }
        
        do {
            try await authService.resetPassword(email: email)
            await showAlert(title: "Success", message: "Password reset email sent!")
        } catch {
            await handleError(error)
        }
    }
    
    func logout() {
        authService.logout()
    }
    
    // MARK: - Private helpers
    @MainActor
    private func restoreSession() async {
        await setLoading(true, message: "Restoring your session...")
        defer { Task { await setLoading(false) } }
        
        _ = try? await authService.restoreSession()
    }
    
    @MainActor
    private func setLoading(_ loading: Bool, message: String = "Loading...") async{
        isLoading = loading
        isLoadingMessage = message
    }
    
    private func validate(email: String, password: String, confirmPassword: String) throws {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            throw AuthError.missingData
        }
        guard password == confirmPassword else {
            throw AuthError.missingData
        }
    }
    
    private func validate(email: String, password: String) throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.missingData
        }
    }
    
    @MainActor
    private func handleError(_ error: Error) async {
        let message: String
        if let authError = error as? AuthError {
            message = authError.localizedDescription
        } else if let nsError = error as NSError?,
                  let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .emailAlreadyInUse:
                message = "An account already exists with this email."
            case .invalidEmail:
                message = "Invalid email format."
            case .weakPassword:
                message = "Password should be at least 6 characters."
            default:
                message = error.localizedDescription
            }
        } else {
            message = error.localizedDescription
        }
        await showAlert(title: "Error", message: message)
    }
    
    private func showAlert(title: String, message: String) async {
        alertItem = AlertItem(title: title, message: message)
    }
}
