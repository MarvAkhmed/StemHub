//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

struct FirestoreUserSaveProvider: UserSaving {
    let db: Firestore
    init(db: Firestore) {
        self.db = db
    }
    
    func save(_ user: User) async throws {
        
        try db.collection(FirestoreCollections.users.path).document(user.id).setData(from: user)
    }
}
