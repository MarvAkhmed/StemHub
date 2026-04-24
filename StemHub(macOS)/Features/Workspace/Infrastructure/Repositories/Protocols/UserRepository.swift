//
//  UserRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol UserDirectoryReading {
    func fetchUser(userId: String) async throws -> User?
    func fetchUsers(userIDs: [String]) async throws -> [User]
}

protocol UserEmailLookup {
    func fetchUser(email: String) async throws -> User?
}

protocol UserCreating {
    func createUser(_ user: User) async throws
}

protocol UserDisplayNameUpdating {
    func updateDisplayName(_ name: String, for userID: String) async throws
}

protocol UserBandAssociating {
    func addBandID(_ bandID: String, for userID: String) async throws
}

protocol UserProjectAssociating {
    func addProjectID(_ projectID: String, for userID: String) async throws
}

protocol UserRepository:
    UserDirectoryReading,
    UserEmailLookup,
    UserCreating,
    UserDisplayNameUpdating,
    UserBandAssociating,
    UserProjectAssociating {}
