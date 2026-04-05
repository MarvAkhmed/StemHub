//
//  AuthorizationViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 30.03.2026.
//

import Foundation
import FirebaseAuth
import SwiftUI
import Combine

protocol AuthorizationViewModelProtocol: ObservableObject {
    func login(user: User) async throws
    func resetPassword(for user: User) async throws
}

final class AuthorizationViewModel: AuthorizationViewModelProtocol, ObservableObject {
    

    @MainActor @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    @Published var showResetSuccessAlert: Bool = false
    
    // login
    func login(user: User) async throws {
        guard let email = user.email, !email.isEmpty,
              let password = user.password, !password.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Please fill in all fields."
            }
            return
        }
        
        await MainActor.run { self.isLoading = true }
        
        do {
            let _ = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                print("Logged in successfully: \(email)")
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run { self.isLoading = false }
    }
    
    // reset
    func resetPassword(for user: User) async throws {
        do {
            try await GoogleAuthService.shared.resetPassword(for: user)
            showResetSuccessAlert = true
        }catch {
            throw ResetPasswordError.failed
        }
    }
}
