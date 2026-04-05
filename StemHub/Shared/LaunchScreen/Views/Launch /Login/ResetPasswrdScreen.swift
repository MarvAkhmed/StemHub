//
//  ResetPasswrdScreen.swift
//  StemHub
//
//  Created by Marwa Awad on 31.03.2026.
//

import Foundation
import SwiftUI
import Combine

struct ResetPasswrdScreen<SVM: SocialLoginViewModelProtocol, AuthVM: AuthViewModelProtocol>: View {
    
    let socialViewModel: SVM
    let authorizationViewModel: AuthVM
    
    @State private var errorMessage: String? = nil
    @State private var email: String = ""
    
    var body: some View {
        ZStack {
            Color.background
                .opacity(0.6)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                buildHeaderTitle()
                    .platformPadding(.bottom, iOS: 40, macOS: 0)
                Spacer()
                VStack {
                    buildTextFields()
                        .platformPadding(.horizontal, iOS: 40, macOS: 0)
                    buildErrorMSG()
                    buildButtons()
                        .platformPadding(.top, iOS: 30, macOS: 30)
                    
                    Spacer()
                }.platformPadding(.horizontal,iOS: 0, macOS: 30)
                Spacer()
                buildHaveAccountLabel()
#if os(macOS)
                Spacer()
#endif
            }
        }
        .platformPadding(iOS: 0, macOS: 200)
        .platformPadding(.top,iOS: 0, macOS: 45)
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

    @ViewBuilder
    private func buildErrorMSG()  -> some View {
        if let error = errorMessage {
            Text(error)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
        }
    }
    @ViewBuilder
    private func buildButtons() -> some View {
        VStack(spacing: 15) {
            Button(action: {
                Task {
                    let tempUser = User(id: "", name: nil, email: email, password: nil)
                    
                         await authorizationViewModel.resetPassword(for: tempUser)
                    
                }
            }) {
                Text("Reset Password")
                    .foregroundColor(.white)
                    .font(.sanchezItalic24)
    #if os(macOS)
                    .frame(width: 240, height: 25)
    #elseif os(iOS)
                    .frame(width: 240, height: 35)
    #endif
            }
            .background(Color.buttonBackground)
            .cornerRadius(10)
        }
    }
    
    @ViewBuilder
    private func buildHaveAccountLabel() -> some View {
        HStack(spacing: 4) {
            Text("Remembered your password?")
                .font(.sanchezRegular16)
                .foregroundColor(.buttonBackground)
            
            Button(action: {
                socialViewModel.didTapLogin()
            }) {
                Text("  Login")
                    .font(.sanchezRegular16)
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .multilineTextAlignment(.center)
    }
}
