//
//  LaunchViewModels.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

@MainActor
struct LaunchViewModels {
    let auth: AuthViewModel
    let social: SocialLoginViewModel
    let terms: TermsAndPrivacyLabelViewModel
}
