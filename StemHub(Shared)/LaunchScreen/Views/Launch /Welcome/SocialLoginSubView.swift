//
//  SocialLoginSubView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

struct SocialLoginSubView: View {
    
    private let viewModel: any SocialLoginViewModelProtocol
    private var termsViewModel: any TermsAndPrivacyLabelViewModelProtocol
    
     init(viewModel: any SocialLoginViewModelProtocol,
          termsViewModel: any TermsAndPrivacyLabelViewModelProtocol) {
         self.viewModel = viewModel
         self.termsViewModel = termsViewModel
     }
    
    var body: some View {
        
        VStack(spacing: 0) {
            buildSeparatorView()
                .platformPadding(.bottom, iOS: 15, macOS: 20)
            
            buildButtons()
                .platformPadding(.bottom,iOS: 20, macOS: 20)
            
            TermsAndPrivacyLabel(viewModel: termsViewModel)
                .platformPadding(.bottom,iOS: 20, macOS: 20)
                .platformPadding(.horizontal, iOS: 40, macOS: 20)
            
            buildHaveAccountLabel()
                .platformPadding(.bottom, iOS: 5, macOS: 20)
                
        }
        .background(Color.background)
        .background(ignoresSafeAreaEdges: .bottom)
    }
    
    @ViewBuilder
    private func buildSeparatorView() -> some View {
        HStack(spacing: 15) {
            Rectangle()
                .fill(Color.white)
                .frame(width: 103, height: 1)
                .background(Color.background)
            
            Text("or continue with")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(minWidth: 50)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: 103, height: 1)
                .background(Color.background)
        }
    }

    @ViewBuilder
    private func buildButtons() -> some View {
        HStack(spacing: 70) {
            Button(action: {
                Task {
                    do {
                        try  await  viewModel.driveSignIn()
                    }
                    catch {
                        throw error
                    }
                }
            }) {
                Image("driveImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            Button(action: {
                Task { try?  await viewModel.iCloudSignIn() }
            }) {
                Image("icloudImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
    @ViewBuilder
    private func buildHaveAccountLabel() -> some View {
        HStack(spacing: 4) {
            Text("Have an account?")
                .font(.sanchezRegular16)
                .foregroundColor(.buttonBackground)
            
            Button(action: {
                viewModel.didTapLogin()
            }) {
                Text("Login")
                    .font(.sanchezRegular16)
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .multilineTextAlignment(.center)
    }
}

