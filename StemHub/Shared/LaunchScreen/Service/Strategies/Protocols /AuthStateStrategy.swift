//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol AuthStateStrategy {
    @MainActor
    func updateState(with user: User, in service: GoogleAuthService)
}
