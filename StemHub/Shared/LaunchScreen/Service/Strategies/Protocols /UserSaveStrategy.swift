//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol UserSaveStrategy {
    func save(_ user: User) async throws
}
