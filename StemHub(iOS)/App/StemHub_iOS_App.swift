//
//  StemHub_iOS_App.swift
//  StemHub
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

@main
struct StemHub_iOS_App: App {
    @UIApplicationDelegateAdaptor(StemHubIOSAppDelegate.self) private var appDelegate
    private let assembler: IOSAppAssembler
    @StateObject private var authenticationViewModel: AuthViewModel
    @StateObject private var socialViewModel: SocialLoginViewModel
    private let termsViewModel: TermsAndPrivacyLabelViewModel
    
    init() {
        FirebaseRuntimeBootstrap.ensureConfigured()
        
        let assembler = IOSAppAssembler()
        self.assembler = assembler
        
        let launchViewModels = assembler.makeLaunchViewModels()
        
        _authenticationViewModel = StateObject(wrappedValue: launchViewModels.auth)
        _socialViewModel = StateObject(wrappedValue: launchViewModels.social)
        termsViewModel = launchViewModels.terms
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authenticationViewModel.isAuthenticated,
                   let user = authenticationViewModel.currentUser {
                    IOSAuthenticatedRootView(
                        currentUser: user,
                        assembler: assembler
                    )
                } else {
                    IOSLaunchView(
                        socialViewModel: socialViewModel,
                        termsViewModel: termsViewModel,
                        authenticationViewModel: authenticationViewModel
                    )
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
