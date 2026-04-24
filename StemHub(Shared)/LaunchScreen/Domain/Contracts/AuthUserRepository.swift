//
//  AuthUserRepository.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

protocol AuthUserRepository {
    func fetchUser(userId: String) async throws -> User?
    func saveUser(_ user: User) async throws
    func updateUser(_ user: User) async throws
}
