//
//  SocialLoginViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI
import Combine

protocol SocialLoginViewModelProtocol: ObservableObject {
    var route: LaunchRoute? { get }
    var isLoading: Bool { get }
    var isLoadingMessage: String { get }
    
    // login
    func driveSignIn() async throws
    func iCloudSignIn() async throws
    
    // switches
    func didTapLogin()
    func didTapSignUp()
    func resetPassword()
    func dismiss()
}

@MainActor
class SocialLoginViewModel: SocialLoginViewModelProtocol {
    
    @Published var route: LaunchRoute? = nil
    @Published var isLoading: Bool = false
    @Published var isLoadingMessage: String = "Loading..."
    
    
    private let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func driveSignIn() async throws {
        await setLoading(true, message: "Connecting to Google...")
        defer { Task { await setLoading(false) } }
        await authViewModel.signInWithGoogle()
    }
    
    func iCloudSignIn() async throws{
        print("iCloudSignIn tapped from the SocialLoginView")
    }
    
    func didTapLogin() {
        route = .login
    }
    
    func didTapSignUp() {
        route = .signUp
    }
    
    func resetPassword() {
        route = .resetPassword
    }
    
    func dismiss() {
        route = nil
    }
    
    @MainActor
    private func setLoading(_ loading: Bool, message: String = "Loading...") async {
        isLoading = loading
        isLoadingMessage = message
    }
}
