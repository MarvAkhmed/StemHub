//
//  FirestoreUserRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreUserRepository: UserRepository, @unchecked Sendable {

    private let db: Firestore
    private let collectionName = FirestoreCollections.users.path

    init(db: Firestore) {
        self.db = db
    }
    
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
            let snapshot = try await db.collection(FirestoreCollections.users.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            users.append(contentsOf: try snapshot.documents.map { try $0.data(as: User.self) })
        }

        return users
    }

    func fetchUser(email: String) async throws -> User? {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else { return nil }

        let snapshot = try await db.collection(FirestoreCollections.users.path)
            .whereField(FirestoreField.email.path, isEqualTo: normalizedEmail)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: User.self)
    }
}
