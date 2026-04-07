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
    
    
    init() {
        let emailProvider = FirebaseEmailAuthProvider()
        let googleProvider = FirebaseGoogleAuthProvider()
        let userRepository = FirebaseUserRepository()
        let userCreation = DefaultUserCreationStrategy()
        let sessionManager = SessionManager(
            userRepository: userRepository,
            userDefaultsManager: UserDefaultsManager.shared
        )
        
        let authService = AuthService(
            emailProvider: emailProvider,
            googleProvider: googleProvider,
            sessionManager: sessionManager,
            userRepository: userRepository,
            userCreation: userCreation
        )
        
        self.authModule = AuthModule(authService: authService)
        self.workspaceModule = WorkspaceModule()
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
    
    func makeWorkspaceViewModel(for user: User) -> WorkspaceViewModel {
        workspaceModule.makeWorkspaceViewModel(currentUser: user)
    }
    
    func makeProjectDetailViewModel(project: Project,
                                    localState: LocalProjectState,
                                    currentUserID: String?) -> ProjectDetailViewModel? {
        guard let currentUserID else { return nil }
        return workspaceModule.makeProjectDetailViewModel(project: project,
                                                          localState: localState,
                                                          currentUserID: currentUserID)
    }
}
