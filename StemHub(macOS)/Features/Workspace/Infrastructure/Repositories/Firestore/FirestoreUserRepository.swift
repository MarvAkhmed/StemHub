//
//  FirestoreUserRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreUserRepository: UserRepository {

    private let db = Firestore.firestore()
    private let collectionName = "users"
    
    func fetchUser(userId: String) async throws -> User? {
        let doc = try await db.collection(collectionName).document(userId).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: User.self)
    }

    func fetchUsers(userIDs: [String]) async throws -> [User] {
        guard !userIDs.isEmpty else { return [] }

        var users: [User] = []
        let chunks = userIDs.chunked(into: 30)

        for chunk in chunks {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            users.append(contentsOf: snapshot.documents.compactMap { try? $0.data(as: User.self) })
        }

        return users
    }

    func fetchUser(email: String) async throws -> User? {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else { return nil }

        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: normalizedEmail)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: User.self)
    }

    func createUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }

    func updateDisplayName(_ name: String, for userID: String) async throws {
        try await db.collection("users")
            .document(userID)
            .updateData(["displayName": name])
    }

    func addBandID(_ bandID: String, for userID: String) async throws {
        try await db.collection("users")
            .document(userID)
            .updateData(["bandIDs": FieldValue.arrayUnion([bandID])])
    }

    func addProjectID(_ projectID: String, for userID: String) async throws {
        try await db.collection("users")
            .document(userID)
            .updateData(["projectIDs": FieldValue.arrayUnion([projectID])])
    }
}

