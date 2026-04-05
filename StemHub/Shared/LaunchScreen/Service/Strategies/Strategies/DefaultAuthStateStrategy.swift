//
//  DefaultAuthStateStrategy.swift.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

struct DefaultAuthStateStrategy: AuthStateStrategy {
    @MainActor
    func updateState(with user: User, in service: GoogleAuthService) {
        service.currentUser = user
        service.isSignedIn = true
    }
}
