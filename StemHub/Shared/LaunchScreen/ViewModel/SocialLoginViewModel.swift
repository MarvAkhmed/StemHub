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
    
    func driveSignIn()  async  throws {
        await MainActor.run {
            isLoading = true
            isLoadingMessage = "Connecting to Google..."
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        do {
            if let user =  try await authViewModel.signInWithDrive() {
                await MainActor.run {
                    self.authViewModel.currentUser = user
                    self.authViewModel.isAuthenticated = true
                }
            }
            
        } catch {
            print("Google Sign-In failed: \(error)")
            throw error
        }
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
}
