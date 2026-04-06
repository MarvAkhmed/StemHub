//
//  LaunchViewMacOS.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

struct EnteryViewMacOS<SVM: SocialLoginViewModelProtocol,
                       TVM: TermsAndPrivacyLabelViewModelProtocol>: View {
    
    @StateObject var socialViewModel: SVM
    @StateObject var termsViewModel: TVM
    @ObservedObject var authorizationViewModel: AuthViewModel
    @State private var isCheckingSession: Bool = true
    
    var body: some View {
      content()
    }
    
    @ViewBuilder
    private func content() -> some View {
        Group {
            if isCheckingSession {
                LoadingView(message: "Checking your session...")
            } else if let user = authorizationViewModel.currentUser,
                      authorizationViewModel.isAuthenticated {
                MainAppShellView(authVM: authorizationViewModel, user: user)
                    .loadingOverlay(
                        isLoading: authorizationViewModel.isLoading,
                        message: authorizationViewModel.isLoadingMessage
                    )
            } else {
                buildLaunchScreen()
                    .loadingOverlay(
                        isLoading: socialViewModel.isLoading || authorizationViewModel.isLoading,
                        message: socialViewModel.isLoading || authorizationViewModel.isLoading
                        ? (socialViewModel.isLoading ? socialViewModel.isLoadingMessage : authorizationViewModel.isLoadingMessage)
                        : "Loading..."
                    )
            }
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCheckingSession = false
            }
        }
    }
    
    @ViewBuilder
    private func buildLaunchScreen() -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            Image(.launch)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            LaunchView(
                socialViewModel: socialViewModel,
                authenticationViewModel: authorizationViewModel,
                termsViewModel: termsViewModel
            )
        }
    }
}



