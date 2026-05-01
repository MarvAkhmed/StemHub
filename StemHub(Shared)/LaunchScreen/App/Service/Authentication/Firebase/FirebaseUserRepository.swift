//
//  UserSaving.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirebaseUserRepository: AuthUserRepository {
    
    private let db: Firestore
    private let collectionName = FirestoreCollections.users.path
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func fetchUser(userId: String) async throws -> User? {
        let doc = try await db.collection(collectionName).document(userId).getDocument()
        return try? doc.data(as: User.self)
    }
    
    func saveUser(_ user: User) async throws {
        try db.collection(collectionName).document(user.id).setData(from: user)
    }
    
    func updateUser(_ user: User) async throws {
        try db.collection(collectionName).document(user.id).setData(from: user, merge: true)
    }
}
