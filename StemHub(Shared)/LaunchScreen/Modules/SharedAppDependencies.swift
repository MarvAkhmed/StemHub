//
//  SharedAppDependencies.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

@MainActor
struct SharedAppDependencies {
    let authService: AuthServiceProtocol
    let authModule: AuthModule
    
    init() {
        FirebaseRuntimeBootstrap.ensureConfigured()
        let configurationLoader = BundleFirebaseConfigurationLoader()
        let configurationValidator = BundleGoogleSignInConfigurationValidator(
            configurationLoader: configurationLoader
        )
        
        let entitlementInspector = SecTaskEntitlementInspector()
        let runtimeValidator = GoogleSignInRuntimeValidator(
            configurationValidator: configurationValidator,
            entitlementInspector: entitlementInspector
        )
        
        let userRepository = FirebaseUserRepository()
        
        let sessionManager = SessionManager(
            userRepository: userRepository,
            userDefaultsManager: UserDefaultsManager.shared,
            authStateProvider: FirebaseAuthStateProvider()
        )

        let authService = AuthService(
            emailProvider: FirebaseEmailAuthProvider(),
            googleProvider: FirebaseGoogleAuth(
                runtimeValidator: runtimeValidator
            ),
            sessionManager: sessionManager,
            userRepository: userRepository
        )

        self.authService = authService
        self.authModule = AuthModule(authService: authService)
    }

    func makeLaunchViewModels() -> LaunchViewModels {
        let auth = authModule.makeAuthViewModel()
        return LaunchViewModels(
            auth: auth,
            social: authModule.makeSocialLoginViewModel(authViewModel: auth),
            terms: authModule.makeTermsViewModel()
        )
    }
}
