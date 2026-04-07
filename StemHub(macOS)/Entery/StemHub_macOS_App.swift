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
    
    private let assembler: AppAssembler
    
    init() {
        Self.configureFirebase()
        Self.configureGoogleSignIn()
        self.assembler = AppAssembler()
    }
    
    var body: some Scene {
        WindowGroup {
            let authVM = assembler.makeAuthViewModel()
            let socialVM = assembler.makeSocialLoginViewModel(authViewModel: authVM)
            let termsVM = assembler.makeTermsViewModel()
            
            EnteryViewMacOS(
                socialViewModel: socialVM,
                termsViewModel: termsVM,
                authorizationViewModel: authVM,
                assembler: assembler
            )
            .preferredColorScheme(.dark)
        }
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
