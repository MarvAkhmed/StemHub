//
//  IOSAppAssembler.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import SwiftUI

@MainActor
struct IOSAppAssembler {
    private let dependencies: SharedAppDependencies
    private let authenticatedFlowModule: IOSAuthenticatedFlowModule
    
    init() {
        let dependencies = SharedAppDependencies()
        let workspaceRepository = FirestoreIOSWorkspaceRepository()
        self.dependencies = dependencies
        self.authenticatedFlowModule = IOSAuthenticatedFlowModule(
            authService: dependencies.authService,
            workspaceRepository: workspaceRepository,
            invitationRepository: FirestoreIOSInvitationRepository(),
            releaseCatalog: FirestoreIOSReleaseCatalog(
                workspaceRepository: workspaceRepository
            ),
            settingsStore: UserDefaultsIOSProducerSettingsStore()
        )
    }
    
    func makeLaunchViewModels() -> LaunchViewModels {
        dependencies.makeLaunchViewModels()
    }
    
    func makeWorkspaceViewModel(currentUser: User) -> WorkspaceViewModel {
        authenticatedFlowModule.makeWorkspaceViewModel(currentUser: currentUser)
    }

    func makeInboxViewModel() -> IOSInboxViewModel {
        authenticatedFlowModule.makeInboxViewModel()
    }

    func makeProfileViewModel() -> IOSProfileViewModel {
        authenticatedFlowModule.makeProfileViewModel()
    }

    func makeSettingsViewModel() -> IOSSettingsViewModel {
        authenticatedFlowModule.makeSettingsViewModel()
    }
}
