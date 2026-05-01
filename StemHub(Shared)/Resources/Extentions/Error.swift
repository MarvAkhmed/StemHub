//
//  Error.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

extension Error {
    var googleSignInErrorCode: GIDSignInError.Code? {
        (self as? GIDSignInError)?.code
    }
}
