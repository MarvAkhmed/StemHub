//
//  ResetPasswrdScreen.swift
//  StemHub
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI

struct ResetPasswrdScreen<SVM: LaunchNavigating, AuthVM: AuthViewModelProtocol>: View {
    
    let socialViewModel: SVM
    let authorizationViewModel: AuthVM
    
    @State private var email: String = ""
    
    var body: some View {
        AuthScreenScaffold(actionsTopPaddingIOS: 30, actionsTopPaddingMacOS: 30) {
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
            .platformPadding(.top, iOS: 40, macOS: 40)
            .platformPadding(.bottom, iOS: 10, macOS: 20)
        
        Text("Reset Passwrd!")
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
        }
    }

    private func buildButtons() -> some View {
        VStack(spacing: 15) {
            AuthActionButton(title: "Reset Password", action: handleResetPasswordTap)
        }
    }
    
    @ViewBuilder
    private func buildHaveAccountRow() -> some View {
        AuthInlineActionRow(
            prefixText: "Remembered your password?",
            actionTitle: "Login",
            action: socialViewModel.didTapLogin
        )
    }

    private func handleResetPasswordTap() {
        Task {
            await authorizationViewModel.resetPassword(email: email)
        }
    }
}
