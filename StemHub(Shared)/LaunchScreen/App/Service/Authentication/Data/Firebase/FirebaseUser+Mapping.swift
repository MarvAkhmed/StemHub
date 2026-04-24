//
//  FirebaseUser+Mapping.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import FirebaseAuth

extension User {
    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.name = firebaseUser.displayName
        self.email = firebaseUser.email
        self.password = nil
        self.bandIDs = []
    }
}
