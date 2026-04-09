//
//  DefaultFirestoreUserStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore

protocol FirestoreUserStrategy {
    func createUser(_ user: User) async throws
    func fetchUser(userID: String) async throws -> User?
    func updateUser(_ user: User) async throws
}


struct DefaultFirestoreUserStrategy: FirestoreUserStrategy {
    private let db = Firestore.firestore()
    
    func createUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }
    
    func fetchUser(userID: String) async throws -> User? {
        let doc = try await db.collection("users").document(userID).getDocument()
        return try? doc.data(as: User.self)
    }
    
    func updateUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user, merge: true)
    }
}
