//
//  IOSAuthenticatedFlowModule.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

@MainActor
struct IOSAuthenticatedFlowModule {
    private let authService: AuthServiceProtocol
    private let workspaceRepository: any IOSWorkspaceLoading
    private let invitationRepository: any IOSInvitationManaging
    private let releaseCatalog: any IOSReleaseCatalogProviding
    private let settingsStore: any IOSProducerSettingsStoring

    init(
        authService: AuthServiceProtocol,
        workspaceRepository: any IOSWorkspaceLoading,
        invitationRepository: any IOSInvitationManaging,
        releaseCatalog: any IOSReleaseCatalogProviding,
        settingsStore: any IOSProducerSettingsStoring
    ) {
        self.authService = authService
        self.workspaceRepository = workspaceRepository
        self.invitationRepository = invitationRepository
        self.releaseCatalog = releaseCatalog
        self.settingsStore = settingsStore
    }

    func makeWorkspaceViewModel(currentUser: User) -> WorkspaceViewModel {
        WorkspaceViewModel(
            currentUser: currentUser,
            authService: authService,
            repository: workspaceRepository
        )
    }

    func makeInboxViewModel() -> IOSInboxViewModel {
        IOSInboxViewModel(
            authService: authService,
            repository: invitationRepository
        )
    }

    func makeProfileViewModel() -> IOSProfileViewModel {
        IOSProfileViewModel(
            authService: authService,
            workspaceRepository: workspaceRepository,
            releaseCatalog: releaseCatalog
        )
    }

    func makeSettingsViewModel() -> IOSSettingsViewModel {
        IOSSettingsViewModel(
            authService: authService,
            store: settingsStore
        )
    }
}
