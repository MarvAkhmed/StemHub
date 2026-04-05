//
//  WelcomeScreen.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

struct WelcomeScreen<SVM: SocialLoginViewModelProtocol, TVM: TermsAndPrivacyLabelViewModelProtocol>: View {
    
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
            
            
            Button(action: {
                viewModel.didTapSignUp()
            }) {
                Text("sign up with Email")
                    .foregroundColor(.white)
                    .font(.sanchezRegular18)
                    .background(Color.buttonBackground)
                    .frame(width: 180, height: 25)
            }
            .frame(width: 180, height: 40)
            .background(Color.buttonBackground)
            .platformPadding(.bottom, iOS: 20, macOS: 20)
            .platformPadding(.top, iOS: 15, macOS: 0)
            .cornerRadius(10)
            
            SocialLoginSubView(
                viewModel: viewModel,
                termsViewModel: termsAndPrivacyLabelViewModel
            )
        }
        .background(Color.background)
    }
}
