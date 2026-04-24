//
//  LaunchRouteDestinationView.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct LaunchRouteDestinationView<
    SVM: LaunchNavigating,
    AVM: AuthViewModelProtocol
>: View {
    let route: LaunchRoute
    let socialViewModel: SVM
    let authenticationViewModel: AVM

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .login:
            LoginScreen(
                socialViewModel: socialViewModel,
                authorizationViewModel: authenticationViewModel
            )
        case .signUp:
            SignUpScreen(
                socialViewModel: socialViewModel,
                authenticationViewModel: authenticationViewModel
            )
        case .resetPassword:
            ResetPasswrdScreen(
                socialViewModel: socialViewModel,
                authorizationViewModel: authenticationViewModel
            )
        }
    }
}
