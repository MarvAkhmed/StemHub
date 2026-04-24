//
//  GoogleSignInProvider.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

protocol GoogleAuthenticating {
    func signInWithGoogle() async throws -> User
    func signIn() async throws -> AuthDataResult
}

protocol SigningOut {
    func signOut() throws
}

typealias GoogleAuth = GoogleAuthenticating & SigningOut
