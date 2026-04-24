//
//  FirebaseAuthStateProvider.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthStateProvider: AuthStateProviding {
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }

    func addStateListener(_ listener: @escaping (AuthStateChange) -> Void) -> AuthStateListenerHandle {
        Auth.auth().addStateDidChangeListener { _, firebaseUser in
            listener(firebaseUser == nil ? .signedOut : .signedIn)
        }
    }

    func removeStateListener(_ handle: AuthStateListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}
