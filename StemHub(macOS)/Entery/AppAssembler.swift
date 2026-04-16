//
//  AppAssembler.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

@MainActor
struct AppAssembler {
    private let authModule: AuthModule
    private let workspaceModule: WorkspaceModule
    private let authService: AuthServiceProtocol
    
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
        
        self.authModule = AuthModule(authService: authService)
        self.workspaceModule = WorkspaceModule(authService: authService)
    }
    
    func makeAuthViewModel() -> AuthViewModel {
        authModule.makeAuthViewModel()
    }
    
    func makeSocialLoginViewModel(authViewModel: AuthViewModel) -> SocialLoginViewModel {
        authModule.makeSocialLoginViewModel(authViewModel: authViewModel)
    }
    
    func makeTermsViewModel() -> TermsAndPrivacyLabelViewModel {
        authModule.makeTermsViewModel()
    }
    
    func makeWorkspaceViewModel() -> WorkspaceViewModel {
        workspaceModule.makeWorkspaceViewModel()
    }
    
    // Updated: now takes only the project; localState is removed
    func makeProjectDetailViewModel(project: Project) -> ProjectDetailViewModel {
        workspaceModule.makeProjectDetailViewModel(project: project)
    }
    
    func getWorkspaceModule() -> WorkspaceModule {
        workspaceModule
    }
}
