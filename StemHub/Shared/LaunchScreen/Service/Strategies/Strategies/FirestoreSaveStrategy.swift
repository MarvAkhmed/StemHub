//
//  FirestoreSaveStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

struct FirestoreSaveStrategy: UserSaveStrategy {
    func save(_ user: User) async throws {
        let db = Firestore.firestore()
        try db.collection("users").document(user.id).setData(from: user)
    }
}
