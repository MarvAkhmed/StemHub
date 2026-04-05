//
//  StemHub_macOS_App.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct StemHub_macOS_App: App {
    
    // MARK: - Shared ViewModels
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var socialViewModel: SocialLoginViewModel
    @StateObject private var termsViewModel = TermsAndPrivacyLabelViewModel()
    
    init() {
        Self.configureFirebase()
        Self.configureGoogleSignIn()
        
        
        let authVM = AuthViewModel()
        let socialVM = SocialLoginViewModel(authViewModel: authVM)
        
        _authViewModel = StateObject(wrappedValue: authVM)
        _socialViewModel = StateObject(wrappedValue: socialVM)
    }
    
    var body: some Scene {
        WindowGroup {
            EnteryViewMacOS(
                socialViewModel: socialViewModel,
                termsViewModel: termsViewModel,
                authorizationViewModel: authViewModel
            )
            .preferredColorScheme(.dark)
        }
    }
}

extension StemHub_macOS_App {
    private static func configureFirebase() {
        if let path = Bundle.main.path(forResource: "GoogleService-Info-macOS", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
        }
    }
    
    private static func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info-macOS", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientID = dict["CLIENT_ID"] as? String else {
            fatalError("Missing CLIENT_ID in GoogleService-Info-macOS.plist")
        }
        
        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration
    }
}
