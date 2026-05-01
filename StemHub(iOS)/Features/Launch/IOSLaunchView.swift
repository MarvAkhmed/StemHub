//
//  IOSLaunchView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

struct IOSLaunchView<SVM: SocialLoginViewModelProtocol,
                     TVM: TermsAndPrivacyLabelViewModelProtocol,
                     AVM: AuthViewModelProtocol>: View {
    
    // Properties 
    @ObservedObject var socialViewModel: SVM
    let termsViewModel: TVM
    @ObservedObject var authenticationViewModel: AVM
    
    // content view
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                launchScreenLayout(in: proxy)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 16))
            }
            .background(Color.background.ignoresSafeArea())
            .sheet(item: routeBinding, content: makeSheetDestination)
        }
        .keyboardAdaptive()
    }

    // view builders
    private func launchScreenLayout(in proxy: GeometryProxy) -> some View {
        VStack {
            Image(.launch)
                .resizable()
                .scaledToFill()
                .frame(height: min(405, max(220, proxy.size.height * 0.36)))
                .frame(maxWidth: .infinity)
                .clipped()
            
            WelcomeScreen(
                viewModel: socialViewModel,
                termsAndPrivacyLabelViewModel: termsViewModel
            )
            .padding(.top, 10)
        }
    }

    // routing action binding
    private var routeBinding: Binding<LaunchRoute?> {
        Binding(
            get: { socialViewModel.route },
            set: { newValue in
                if newValue == nil {
                    socialViewModel.dismiss()
                }
            }
        )
    }

    private func makeSheetDestination(for route: LaunchRoute) -> some View {
        LaunchRouteDestinationView(
            route: route,
            socialViewModel: socialViewModel,
            authenticationViewModel: authenticationViewModel
        )
    }
}
