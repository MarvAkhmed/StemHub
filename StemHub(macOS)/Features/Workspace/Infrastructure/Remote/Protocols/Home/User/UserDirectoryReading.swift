//
//  UserDirectoryReading.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol UserDirectoryReading: Sendable {
    func fetchUser(userId: String) async throws -> User?
    func fetchUsers(userIDs: [String]) async throws -> [User]
}
