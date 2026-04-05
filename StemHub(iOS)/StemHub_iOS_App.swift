//
//  StemHub_iOS_App.swift
//  StemHub
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI
import Firebase

@main
struct StemHub_iOS_App: App {
    @StateObject private var authenticationViewModel: AuthViewModel
    @StateObject private var socialViewModel: SocialLoginViewModel
    @StateObject private var termsViewModel = TermsAndPrivacyLabelViewModel()
    
    let tabs = [
        AppTab(id: "Work Space", title: "Work Space", systemImage: "house.fill"),
        AppTab(id: "profile", title: "Profile", systemImage: "person.fill"),
        AppTab(id: "settings", title: "Settings", systemImage: "gearshape.fill")
    ]
    
    init() {
        FirebaseApp.configure()
        
        let authVM = AuthViewModel()
        let socialVM = SocialLoginViewModel(authViewModel: authVM)
        
        _authenticationViewModel = StateObject(wrappedValue: authVM)
        _socialViewModel = StateObject(wrappedValue: socialVM)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authenticationViewModel.isAuthenticated {
                    MainAppTabView_iOS(
                        tabs: tabs,
                        initialTab: tabs.first!.id,
                        content: { tab in AnyView(contentView(for: tab)) },
                        label: { tab in Label(tab.title, systemImage: tab.systemImage)  }
                    )
                } else {
                    launchView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private func launchView() -> some View {
        LaunchView_iOS(socialViewModel: socialViewModel,
                       termsViewModel: termsViewModel,
                       authenticationViewModel: authenticationViewModel)
    }
    
    @ViewBuilder
    private func contentView(for tab: AppTab) -> some View {
        switch tab.id {
        case "Work Space": WorkSpaceView()
        case "profile": EmptyView()
        case "settings": EmptyView()
        default: EmptyView()
        }
    }
}
