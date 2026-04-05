//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol UserFetchStrategy {
    func fetch(userId: String) async throws -> User?
}
