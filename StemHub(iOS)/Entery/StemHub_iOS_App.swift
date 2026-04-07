//
//  StemHub_iOS_App.swift
//  StemHub
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI
import Firebase
import GoogleSignIn
@main
struct StemHub_iOS_App: App {
    private let assembler: AppAssembler_iOS
    @StateObject private var authenticationViewModel: AuthViewModel
    @StateObject private var socialViewModel: SocialLoginViewModel
    @StateObject private var termsViewModel: TermsAndPrivacyLabelViewModel
    
    private let tabs = [
        AppTab(id: "workspace", title: "Work Space", systemImage: "house.fill")
    ]
    
    init() {
        Self.configureFirebase()
        Self.configureGoogleSignIn()
        
        let assembler = AppAssembler_iOS()
        self.assembler = assembler
        
        let authVM = assembler.makeAuthViewModel()
        let socialVM = assembler.makeSocialLoginViewModel(authViewModel: authVM)
        let termsVM = assembler.makeTermsViewModel()
        
        _authenticationViewModel = StateObject(wrappedValue: authVM)
        _socialViewModel = StateObject(wrappedValue: socialVM)
        _termsViewModel = StateObject(wrappedValue: termsVM)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authenticationViewModel.isAuthenticated,
                   let user = authenticationViewModel.currentUser {
                    let workspaceVM = assembler.makeWorkspaceViewModel(currentUser: user)
                    MainAppTabView_iOS(
                        tabs: tabs,
                        initialTab: tabs.first!.id
                    ) { tab in
                        WorkSpaceView(viewModel: workspaceVM)
                    }
                } else {
                    launchView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private func launchView() -> some View {
        LaunchView_iOS(
            socialViewModel: socialViewModel,
            termsViewModel: termsViewModel,
            authenticationViewModel: authenticationViewModel
        )
    }
    
    private static func configureFirebase() {
        FirebaseApp.configure()
    }
    
    private static func configureGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("Missing clientID – check GoogleService-Info.plist")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
}
