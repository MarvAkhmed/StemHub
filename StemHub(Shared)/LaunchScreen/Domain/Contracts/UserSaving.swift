//
//  UserSaving.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

protocol UserSaving {
    func save(_ user: User) async throws
}
