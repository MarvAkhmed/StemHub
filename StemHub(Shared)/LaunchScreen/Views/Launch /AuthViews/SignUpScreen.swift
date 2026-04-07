//
//  SignUpScreen.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI
import FirebaseAuth

struct SignUpScreen<SVM: SocialLoginViewModelProtocol, AVM: AuthViewModelProtocol>: View {
    
    let socialViewModel: SVM
    let authenticationViewModel: AVM
    
    
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    
    @FocusState private var focusedField: Field?
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
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
                    await authenticationViewModel.signUp(
                        email: email,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                }
            }) {
                Text("Sign Up")
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
            
            Button(action: {  socialViewModel.dismiss() }) {
                Text("Back")
                    .foregroundColor(.white)
                    .font(.sanchezItalic24)
#if os(macOS)
                    .frame(width: 240, height: 25)
#elseif os(iOS)
                    .frame(width: 240, height: 35)
#endif
                    .cornerRadius(10)
            }
            .background(Color.gray.opacity(0.6))
            .cornerRadius(10)
        }.platformPadding(.top, iOS: 10, macOS: 45)
    }
    
    @ViewBuilder
    private func buildHaveAccountLabel() -> some View {
        HStack(spacing: 4) {
            Text("Have an account?")
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
    
    private func checkAllFieldsAreFilled() {
        guard !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
    }
    
    private func checkPasswordMatch() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match!"
            return
        }
    }
}


