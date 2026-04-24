//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

struct FirestoreUserSaveProvider: UserSaving {
    func save(_ user: User) async throws {
        let db = Firestore.firestore()
        try db.collection("users").document(user.id).setData(from: user)
    }
}
