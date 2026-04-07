//
//  WorkspaceViewModel.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import Combine

@MainActor
final class WorkspaceViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    let currentUser: User
    
    init(currentUser: User, authService: AuthServiceProtocol) {
        self.currentUser = currentUser
        self.authService = authService
    }
    
    func logout() {
        authService.logout()
    }
}
