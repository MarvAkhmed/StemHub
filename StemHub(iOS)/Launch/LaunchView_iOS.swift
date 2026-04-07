//
//  LaunchView_iOS.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

struct LaunchView_iOS<SVM: SocialLoginViewModelProtocol,
                      TVM: TermsAndPrivacyLabelViewModelProtocol,
                      AVM: AuthViewModelProtocol>: View {
    
    @StateObject var socialViewModel: SVM
    @StateObject var termsViewModel: TVM
    @ObservedObject var authenticationViewModel: AVM
    
    var body: some View {
        VStack(spacing: 0) {
            Image(.launch)
                .resizable()
                .scaledToFill()
                .frame(height: 405)
                .frame(maxWidth: .infinity)
                .clipped()
            
            WelcomeScreen(
                viewModel: socialViewModel,
                termsAndPrivacyLabelViewModel: termsViewModel
            )
            .padding(.top, 10)
        }
        .keyboardAdaptive()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .ignoresSafeArea(edges: [.top, .bottom])
        
        .sheet(item: Binding<LaunchRoute?>(
            get: { socialViewModel.route },
            set: { _ in  }
        )) { route in
            switch route {
            case .login:
                LoginScreen(
                    socialViewModel: socialViewModel,
                    authorizationViewModel: authenticationViewModel
                )
            case .signUp:
                SignUpScreen(
                    socialViewModel: socialViewModel,
                    authenticationViewModel: authenticationViewModel
                )
            case .resetPassword:
                ResetPasswrdScreen(
                    socialViewModel: socialViewModel,
                    authorizationViewModel: authenticationViewModel
                )
            case .none:
                EmptyView()
            }
            
        }
    }
}
