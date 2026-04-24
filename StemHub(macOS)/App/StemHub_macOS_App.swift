//
//  StemHub_macOS_App.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

private enum MacOSWindowMetrics {
    static let defaultWidth: CGFloat = 1100
    static let defaultHeight: CGFloat = 740
}

@main
struct StemHub_macOS_App: App {
    @NSApplicationDelegateAdaptor(StemHubMacOSAppDelegate.self) private var appDelegate
    
    private let assembler: AppAssembler
    @StateObject private var authenticationViewModel: AuthViewModel
    @StateObject private var socialViewModel: SocialLoginViewModel
    private let termsViewModel: TermsAndPrivacyLabelViewModel
    
    init() {
        FirebaseRuntimeBootstrap.ensureConfigured()
        let assembler = AppAssembler()
        self.assembler = assembler

        let launchViewModels = assembler.makeLaunchViewModels()
        _authenticationViewModel = StateObject(wrappedValue: launchViewModels.auth)
        _socialViewModel = StateObject(wrappedValue: launchViewModels.social)
        termsViewModel = launchViewModels.terms
    }
    
    var body: some Scene {
        WindowGroup {
            MacOSRootView(
                socialViewModel: socialViewModel,
                termsViewModel: termsViewModel,
                authorizationViewModel: authenticationViewModel,
                assembler: assembler
            )
            .preferredColorScheme(.dark)
        }
        .defaultSize(
            width: MacOSWindowMetrics.defaultWidth,
            height: MacOSWindowMetrics.defaultHeight
        )
    }
}
