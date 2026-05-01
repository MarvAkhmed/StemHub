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
                await finishInitialLoading()
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if isCheckingSession {
            LoadingView(message: "Checking your session...")
        } else if authorizationViewModel.currentUser != nil,
                  authorizationViewModel.isAuthenticated {
            
            assembler.workspaceModule.makeMainAppShellView(authVM: authorizationViewModel)
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
    
    private func finishInitialLoading() async {
        guard isCheckingSession,
              !Task.isCancelled else { return }

        await Task.yield()
        isCheckingSession = false
    }
}
