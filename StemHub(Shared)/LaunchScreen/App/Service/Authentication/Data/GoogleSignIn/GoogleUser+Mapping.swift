//
//  GoogleUser+Mapping.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import GoogleSignIn

extension User {
    init(googleUser: GIDGoogleUser) {
        self.id = googleUser.userID ?? (UUID().uuidString)
        self.name = googleUser.profile?.name
        self.email = googleUser.profile?.email
        self.password = nil
    }
}
