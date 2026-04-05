//
//  LaunchState.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import Foundation

enum LaunchRoute: Identifiable {
    case login
    case signUp
    case resetPassword
    case none
    var id: String {
        switch self {
        case .login: return "login"
        case .signUp: return "signUp"
        case .resetPassword: return "restPaswrd"
        case .none: return "none"
        }
    }
}
