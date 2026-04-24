//
//  MacOSRootView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

struct MacOSRootView<SVM: SocialLoginViewModelProtocol,
                     TVM: TermsAndPrivacyLabelViewModelProtocol>: View {
    
    @ObservedObject var socialViewModel: SVM
    let termsViewModel: TVM
    @ObservedObject var authorizationViewModel: AuthViewModel
    @State private var isCheckingSession: Bool = true
    let assembler: AppAssembler
    
    var body: some View {
        content
            .task {
                await completeSessionCheck()
            }
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            if isCheckingSession {
                LoadingView(message: "Checking your session...")
            } else if let _ = authorizationViewModel.currentUser,
                      authorizationViewModel.isAuthenticated {
                MainAppShellView(
                    authVM: authorizationViewModel,
                    module: assembler.workspaceModule
                )
                .loadingOverlay(
                    isLoading: authorizationViewModel.isLoading,
                    message: authorizationViewModel.isLoadingMessage
                )
            } else {
                buildLaunchScreen()
                    .loadingOverlay(
                        isLoading: authorizationViewModel.isLoading,
                        message: authorizationViewModel.isLoadingMessage
                    )
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

    private func completeSessionCheck() async {
        guard isCheckingSession else { return }

        try? await Task.sleep(for: .milliseconds(500))

        guard !Task.isCancelled else { return }
        isCheckingSession = false
    }
}
