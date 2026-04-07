//
//  AuthModule.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

@MainActor
struct AuthModule {
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService)
    }
    
    func makeSocialLoginViewModel(authViewModel: AuthViewModel) -> SocialLoginViewModel {
        SocialLoginViewModel(authViewModel: authViewModel)
    }
    
    func makeTermsViewModel() -> TermsAndPrivacyLabelViewModel {
        TermsAndPrivacyLabelViewModel()
    }
}
