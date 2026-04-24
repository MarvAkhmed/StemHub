//
//  LaunchView.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

struct LaunchView<
    SVM: SocialLoginViewModelProtocol,
    AVM: AuthViewModelProtocol,
    TVM: TermsAndPrivacyLabelViewModelProtocol
>: View {

    @ObservedObject var socialViewModel: SVM
    @ObservedObject var authenticationViewModel: AVM
    let termsViewModel: TVM

    var body: some View {
        LaunchRouteContentView(
            socialViewModel: socialViewModel,
            authenticationViewModel: authenticationViewModel,
            termsViewModel: termsViewModel
        )
        .alert(item: $authenticationViewModel.alertItem, content: makeAlert)
    }

    private func makeAlert(for alert: AlertItem) -> Alert {
        Alert(
            title: Text(alert.title),
            message: Text(alert.message),
            dismissButton: .default(Text("OK"))
        )
    }
}
