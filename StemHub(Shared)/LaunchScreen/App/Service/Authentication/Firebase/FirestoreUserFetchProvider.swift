//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

struct FirestoreUserFetchProvider: UserFetching {
    func fetch(userId: String) async throws -> User? {
        let db = Firestore.firestore()
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        if userDoc.exists {
            return try userDoc.data(as: User.self)
        }
        return nil
    }
}
