//
//  SignUpScreen.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

struct SignUpScreen<SVM: LaunchNavigating, AVM: AuthViewModelProtocol>: View {
    
    let socialViewModel: SVM
    let authenticationViewModel: AVM
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        AuthScreenScaffold(actionsTopPaddingIOS: 10, actionsTopPaddingMacOS: 45) {
            buildHeaderTitle()
        } fields: {
            buildTextFields()
        } actions: {
            buildButtons()
        } footer: {
            buildHaveAccountRow()
        }
    }
    
    
    @ViewBuilder
    private func buildHeaderTitle() -> some View {
        Text("StemHub")
            .font(.sanchezRegular32)
            .foregroundStyle(.white)
            .platformPadding(.top, iOS: 50, macOS: 40)
            .platformPadding(.bottom, iOS: 10, macOS: 20)
        
        Text("Create your account to get started")
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
            GradientFocusTextField(text: $confirmPassword, placeholder: "confirm password", isSecure: true  )
        }
    }

    private func buildButtons() -> some View {
        VStack(spacing: 15) {
            AuthActionButton(title: "Sign Up", action: handleSignUpTap)
            AuthActionButton(title: "Back", variant: .secondary, action: socialViewModel.dismiss)
        }
    }
    
    @ViewBuilder
    private func buildHaveAccountRow() -> some View {
        AuthInlineActionRow(
            prefixText: "Have an account?",
            actionTitle: "Login",
            action: socialViewModel.didTapLogin
        )
    }

    private func handleSignUpTap() {
        Task {
            await authenticationViewModel.signUp(
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )
        }
    }
}
