//
//  UserAuthOrchestrator.swift
//  StemHub
//
//  Created by Marwa Awad on 28.03.2026.
//

import Foundation
import FirebaseAuth

actor UserAuthOrchestrator {
    private let fetchStrategy: UserFetchStrategy
    private let saveStrategy: UserSaveStrategy
    private let creationStrategy: UserCreationStrategy
    private let stateStrategy: AuthStateStrategy
    private weak var authService: GoogleAuthService?
    
    init(
        fetchStrategy: UserFetchStrategy,
        saveStrategy: UserSaveStrategy,
        creationStrategy: UserCreationStrategy,
        stateStrategy: AuthStateStrategy,
        authService: GoogleAuthService
    ) {
        self.fetchStrategy = fetchStrategy
        self.saveStrategy = saveStrategy
        self.creationStrategy = creationStrategy
        self.stateStrategy = stateStrategy
        self.authService = authService
    }
    
    func processUserAfterAuth(authResult: AuthDataResult, email: String, name: String?) async throws -> User {
        let existingUser = try await fetchStrategy.fetch(userId: authResult.user.uid)
        
        if let existingUser = existingUser {
            if let service = authService {
                await stateStrategy.updateState(with: existingUser, in: service)
            }
            return existingUser
        }
        
        let newUser = await creationStrategy.create(from: authResult, email: email, name: name)
        try await saveStrategy.save(newUser)
        
        if let service = authService {
            await stateStrategy.updateState(with: newUser, in: service)
        }
        
        return newUser
    }
}
