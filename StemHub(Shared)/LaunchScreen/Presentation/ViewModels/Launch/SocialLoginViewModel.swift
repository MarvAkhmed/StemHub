//
//  SocialLoginViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import Foundation
import Combine

@MainActor
final class SocialLoginViewModel: SocialLoginViewModelProtocol {
    
    @Published var route: LaunchRoute? = nil
    
    private let authViewModel: any AuthViewModelProtocol
    
    init(authViewModel: any AuthViewModelProtocol) {
        self.authViewModel = authViewModel
    }
    
    func driveSignIn() async {
        await authViewModel.signInWithGoogle()
    }
    
    func iCloudSignIn() async {
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
