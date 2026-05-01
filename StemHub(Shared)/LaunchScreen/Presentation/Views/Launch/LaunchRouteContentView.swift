//
//  LaunchRouteContentView.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct LaunchRouteContentView<
    SVM: SocialLoginViewModelProtocol,
    AVM: AuthViewModelProtocol,
    TVM: TermsAndPrivacyLabelViewModelProtocol
>: View {
    @ObservedObject var socialViewModel: SVM
    let authenticationViewModel: AVM
    let termsViewModel: TVM

    var body: some View {
        if let route = socialViewModel.route {
            LaunchRouteDestinationView(
                route: route,
                socialViewModel: socialViewModel,
                authenticationViewModel: authenticationViewModel
            )
        } else {
            WelcomeScreen(
                viewModel: socialViewModel,
                termsAndPrivacyLabelViewModel: termsViewModel
            )
        }
    }
}
