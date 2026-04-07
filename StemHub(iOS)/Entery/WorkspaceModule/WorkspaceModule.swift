//
//  WorkspaceModule_iOS.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import SwiftUI

@MainActor
struct WorkspaceModule {
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func makeWorkspaceViewModel(currentUser: User) -> WorkspaceViewModel {
        WorkspaceViewModel(currentUser: currentUser, authService: authService)
    }
}
