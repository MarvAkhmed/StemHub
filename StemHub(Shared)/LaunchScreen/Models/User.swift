//
//  User.swift
//  StemHub
//
//  Created by Marwa Awad on 30.03.2026.
//

import Foundation
import GoogleSignIn
import FirebaseAuth

struct User: Identifiable, Codable {
    let id: String
    let name: String?
    let email: String?
    let password: String?
    var bandIDs: [String] = []
    
    init(googleUser: GIDGoogleUser) {
        self.id = googleUser.userID ?? (UUID().uuidString)
        self.name = googleUser.profile?.name
        self.email = googleUser.profile?.email
        self.password = nil
    }
    
    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.name = firebaseUser.displayName
        self.email = firebaseUser.email
        self.password = nil
        self.bandIDs = []
    }
    
    init(id: String = UUID().uuidString, name: String? = nil, email: String?, password: String?, bandIDs: [String] = []) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.bandIDs = bandIDs
    }
}
