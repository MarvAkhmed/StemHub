//
//  WelcomeScreen.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

struct WelcomeScreen<SVM: LaunchNavigating & SocialSignInDriving, TVM: TermsAndPrivacyLabelViewModelProtocol>: View {
    
    let viewModel: SVM
    let termsAndPrivacyLabelViewModel: TVM
    
    var body: some View {
        VStack {
            Text("Git-Music")
                .font(.sanchezRegular32)
                .foregroundStyle(.white)
                .platformPadding(.top, iOS: 15, macOS: 40)
                .platformPadding(.bottom, iOS: 10, macOS: 20)
            
            Text("Your team's single source of truth")
                .font(.sanchezRegular24)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .platformPadding(.bottom, iOS: 10, macOS: 20)
                .platformPadding(.horizontal, iOS: 40, macOS: 0)
            
            AuthActionButton(
                title: "Sign Up With Email",
                action: viewModel.didTapSignUp
            )
            .platformPadding(.bottom, iOS: 20, macOS: 20)
            .platformPadding(.top, iOS: 15, macOS: 0)
            
            SocialLoginSubView(
                viewModel: viewModel,
                termsViewModel: termsAndPrivacyLabelViewModel
            )
        }
        .background(Color.background)
    }
}
