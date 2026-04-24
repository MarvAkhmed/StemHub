//
//  LoginScreen.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

struct LoginScreen<SVM: LaunchNavigating, AVM: AuthViewModelProtocol>: View {
    
    let socialViewModel: SVM
    let authorizationViewModel: AVM
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        AuthScreenScaffold(actionsTopPaddingIOS: 10, actionsTopPaddingMacOS: 45) {
            buildHeaderTitle()
        } fields: {
            buildTextFields()
        } actions: {
            buildButtons()
            resetPasswordRow()
                .platformPadding(.top, iOS: 10, macOS: 10)
        } footer: {
            buildCreateAccountRow()
        }
    }
    
    
    @ViewBuilder
    private func buildHeaderTitle() -> some View {
        Text("StemHub")
            .font(.sanchezRegular32)
            .foregroundStyle(.white)
            .platformPadding(.top, iOS: 40, macOS: 40)
            .platformPadding(.bottom, iOS: 10, macOS: 20)
        
        Text("Welcome back! Log in to continue")
            .font(.sanchezRegular24)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .platformPadding(.horizontal, iOS: 40, macOS: 0)
    }
    
    @ViewBuilder
    private func buildTextFields() -> some View {
        VStack(spacing: 15) {
            GradientFocusTextField(text: $email, placeholder: "Email", isSecure: false )
            GradientFocusTextField(text: $password, placeholder: "password", isSecure: true  )
        }
    }
    
    private func buildButtons() -> some View {
        VStack(spacing: 15) {
            AuthActionButton(title: "Login", action: handleLoginTap)
            AuthActionButton(title: "Back", variant: .secondary, action: socialViewModel.dismiss)
        }
    }
    
    @ViewBuilder
    private func resetPasswordRow() -> some View {
        AuthInlineActionRow(
            prefixText: "Forgot Password?",
            actionTitle: "Reset",
            action: socialViewModel.resetPassword
        )
    }
    
    @ViewBuilder
    private func buildCreateAccountRow() -> some View {
        AuthInlineActionRow(
            prefixText: "Create new Account:",
            actionTitle: "Sign Up",
            action: socialViewModel.didTapSignUp
        )
    }

    private func handleLoginTap() {
        Task {
            await authorizationViewModel.signIn(email: email, password: password)
        }
    }
}
