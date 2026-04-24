//
//  AuthFormValidating.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol AuthFormValidating {
    func validateSignUp(email: String, password: String, confirmPassword: String) throws
    func validateSignIn(email: String, password: String) throws
    func validateResetPassword(email: String) throws
}
