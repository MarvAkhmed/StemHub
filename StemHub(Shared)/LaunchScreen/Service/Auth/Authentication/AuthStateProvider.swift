//
//  AuthStateProvider.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseAuth

typealias AuthStateListenerHandle = AuthStateDidChangeListenerHandle

enum AuthStateChange {
    case signedIn(User)
    case signedOut
}

protocol AuthStateProvider {
    var currentFirebaseUser: FirebaseAuth.User? { get }
    func addStateListener(_ listener: @escaping (AuthStateChange) -> Void) -> AuthStateListenerHandle
    func removeStateListener(_ handle: AuthStateListenerHandle)
}

extension AuthStateProvider {
    func removeStateListener(_ handle: AuthStateListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}
