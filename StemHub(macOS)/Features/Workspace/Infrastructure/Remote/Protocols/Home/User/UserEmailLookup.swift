//
//  UserEmailLookup.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol UserEmailLookup: Sendable {
    func fetchUser(email: String) async throws -> User?
}
