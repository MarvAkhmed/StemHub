//
//  FirestoreUserRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol

protocol UserRepository {
    func fetchUser(userID: String) async throws -> User?
    func createUser(_ user: User) async throws
    func updateDisplayName(_ name: String, for userID: String) async throws
    func addProjectID(_ projectID: String, for userID: String) async throws
}

// MARK: - Implementation

final class FirestoreUserRepository: UserRepository {

    private let db = Firestore.firestore()

    func fetchUser(userID: String) async throws -> User? {
        let doc = try await db.collection("users").document(userID).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: User.self)
    }

    func createUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }

    func updateDisplayName(_ name: String, for userID: String) async throws {
        try await db.collection("users")
            .document(userID)
            .updateData(["displayName": name])
    }

    func addProjectID(_ projectID: String, for userID: String) async throws {
        try await db.collection("users")
            .document(userID)
            .updateData(["projectIDs": FieldValue.arrayUnion([projectID])])
    }
}
