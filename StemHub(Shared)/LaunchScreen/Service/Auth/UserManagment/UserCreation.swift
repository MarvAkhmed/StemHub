//
//  UserCreation.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseAuth

protocol UserCreation {
    func createUser(from authResult: AuthDataResult, name: String?) async throws -> User
}

final class DefaultUserCreationStrategy: UserCreation {
    func createUser(from authResult: AuthDataResult, name: String?) async throws -> User {
        return User(
            id: authResult.user.uid,
            name: name ?? authResult.user.displayName,
            email: authResult.user.email,
            password: nil,
            bandIDs: []
        )
    }
}
