//
//  AuthStateProviding.swift.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

typealias AuthStateListenerHandle = NSObjectProtocol

protocol AuthStateProviding {
    var currentUserID: String? { get }

    func addStateListener(_ listener: @escaping (AuthStateChange) -> Void) -> AuthStateListenerHandle
    func removeStateListener(_ handle: AuthStateListenerHandle)
}
