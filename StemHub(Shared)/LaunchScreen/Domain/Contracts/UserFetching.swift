//
//  UserFetching.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

protocol UserFetching {
    func fetch(userId: String) async throws -> User?
}
