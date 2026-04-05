//
//  DefaultUserCreationStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseAuth

struct DefaultUserCreationStrategy: UserCreationStrategy {
    func create(from authResult: AuthDataResult, email: String, name: String?) -> User {
        User(
            id: authResult.user.uid,
            name: name ?? authResult.user.displayName ?? "User",
            email: email,
            password: nil,
            bandIDs: []
        )
    }
}
