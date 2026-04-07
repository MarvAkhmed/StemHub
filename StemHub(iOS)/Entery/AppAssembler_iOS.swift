//
//  AppAssembler_iOS.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import SwiftUI

@MainActor
struct AppAssembler_iOS {
    private let authService: AuthServiceProtocol
    private let workspaceModule: WorkspaceModule
    
    init() {
        let emailProvider = FirebaseEmailAuthProvider()
        let googleProvider = FirebaseGoogleAuthProvider()
        let userRepository = FirebaseUserRepository()
        let userCreation = DefaultUserCreationStrategy()
        let sessionManager = SessionManager(
            userRepository: userRepository,
            userDefaultsManager: UserDefaultsManager.shared
        )
        
        self.authService = AuthService(
            emailProvider: emailProvider,
            googleProvider: googleProvider,
            sessionManager: sessionManager,
            userRepository: userRepository,
            userCreation: userCreation
        )
        
        self.workspaceModule = WorkspaceModule(authService: authService)
    }
    
    // Auth factories
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService)
    }
    
    func makeSocialLoginViewModel(authViewModel: AuthViewModel) -> SocialLoginViewModel {
        SocialLoginViewModel(authViewModel: authViewModel)
    }
    
    func makeTermsViewModel() -> TermsAndPrivacyLabelViewModel {
        TermsAndPrivacyLabelViewModel()
    }
    
    // Workspace
    func makeWorkspaceViewModel(currentUser: User) -> WorkspaceViewModel {
        workspaceModule.makeWorkspaceViewModel(currentUser: currentUser)
    }
}
