//
//  LaunchView.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

struct LaunchView<
    SVM: SocialLoginViewModelProtocol,
    AVM: AuthViewModelProtocol,
    TVM: TermsAndPrivacyLabelViewModelProtocol
>: View {
    
    
    @ObservedObject var socialViewModel: SVM
    @ObservedObject var authenticationViewModel: AVM
    @ObservedObject var termsViewModel: TVM
    
    
    var body: some View {
        ZStack {
            switch socialViewModel.route {
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
                
            default:
                WelcomeScreen(
                    viewModel: socialViewModel,
                    termsAndPrivacyLabelViewModel: termsViewModel
                )
            }
        }
        .alert(item: $authenticationViewModel.alertItem) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
