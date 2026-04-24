//
//  DefaultFirebaseEmailStrategy.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation
import FirebaseAuth

final class FirebaseEmailAuthProvider: EmailAuthenticator {
    
    func signUp(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return User(firebaseUser: result.user)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let result =  try await Auth.auth().signIn(withEmail: email, password: password)
        return User(firebaseUser: result.user)
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
