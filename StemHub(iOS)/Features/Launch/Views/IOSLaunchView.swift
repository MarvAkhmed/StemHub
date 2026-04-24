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
    
    @ObservedObject var socialViewModel: SVM
    let termsViewModel: TVM
    @ObservedObject var authenticationViewModel: AVM
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                launchScreenLayout(in: proxy)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 16))
            }
            .background(backgroundLayer)
            .sheet(item: routeBinding, content: makeSheetDestination)
        }
        .keyboardAdaptive()
    }

    private func launchScreenLayout(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            launchArtwork(in: proxy)
            WelcomeScreen(
                viewModel: socialViewModel,
                termsAndPrivacyLabelViewModel: termsViewModel
            )
            .padding(.top, 10)
        }
    }

    private func launchArtwork(in proxy: GeometryProxy) -> some View {
        Image(.launch)
            .resizable()
            .scaledToFill()
            .frame(height: launchArtworkHeight(for: proxy))
            .frame(maxWidth: .infinity)
            .clipped()
    }

    private var backgroundLayer: some View {
        Color.background.ignoresSafeArea()
    }

    private func launchArtworkHeight(for proxy: GeometryProxy) -> CGFloat {
        min(405, max(220, proxy.size.height * 0.36))
    }

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
