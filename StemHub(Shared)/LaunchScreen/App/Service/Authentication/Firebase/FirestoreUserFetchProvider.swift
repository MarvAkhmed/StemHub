//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

struct FirestoreUserFetchProvider: UserFetching {
    let db: Firestore
    init(db: Firestore) {
        self.db = db
    }
    
    func fetch(userId: String) async throws -> User? {
        let userDoc = try await db.collection(FirestoreCollections.users.path).document(userId).getDocument()
        
        if userDoc.exists {
            return try userDoc.data(as: User.self)
        }
        return nil
    }
}
