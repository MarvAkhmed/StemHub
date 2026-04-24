//
//  WorkspaceModule.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

@MainActor
final class WorkspaceModule {
    private let dependencies: WorkspaceDependencyContainer
    private let services: WorkspaceServiceContainer
    private let pickerService = FilePickerService()

    // MARK: - Init
    init(authService: AuthServiceProtocol) {
        let dependencies = WorkspaceDependencyContainer(authService: authService)
        self.dependencies = dependencies
        self.services = WorkspaceServiceContainer(dependencies: dependencies)
    }

    func makeWorkspaceViewModel() -> WorkspaceViewModel {
        WorkspaceViewModel(
            authService: dependencies.authService,
            workspaceCatalogService: services.workspaceCatalogService,
            projectCreation: services.projectCreation,
            projectDeletionService: services.projectDeletionService,
            syncService: services.syncService,
            stateStore: dependencies.stateStore
        )
    }

    func makeShellViewModel() -> MainAppShellViewModel {
        MainAppShellViewModel()
    }

    func makeNotificationsViewModel() -> NotificationsViewModel {
        NotificationsViewModel(
            authService: dependencies.authService,
            invitationService: services.invitationService
        )
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            authService: dependencies.authService,
            workspaceLoader: services.workspaceLoader,
            releaseCatalog: services.releaseCatalogService
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            authService: dependencies.authService,
            store: dependencies.producerSettingsStore
        )
    }

    func makeNewProjectSheetViewModel(workspaceViewModel: WorkspaceViewModel) -> NewProjectSheetViewModel {
        NewProjectSheetViewModel(
            workspaceProjectCreator: workspaceViewModel,
            folderPicker: pickerService,
            imagePicker: pickerService,
            userRepository: dependencies.userRepository,
            folderMetadataProvider: ProjectFolderMetadataService()
        )
    }

    func makeProjectDetailViewModel(project: Project) -> ProjectDetailViewModel {
        return ProjectDetailViewModel(
            project: project,
            authService: dependencies.authService,
            syncService: services.syncService,
            versionService: services.versionService,
            versionApprovalService: services.versionApprovalService,
            branchService: services.branchService,
            collaborationService: services.collaborationService,
            commentService: services.commentService,
            localCommitStore: dependencies.localCommitStore,
            folderService: services.folderService,
            stateStore: dependencies.stateStore,
            projectRepository: dependencies.projectRepository,
            midiSessionResolver: services.midiSessionResolver,
            folderPicker: pickerService,
            audioPicker: pickerService,
            imagePicker: pickerService,
            posterEncoder: dependencies.posterEncoder,
            audioPlaybackPreparer: DefaultAudioPlaybackPreparer(),
            defaultPlaybackRate: dependencies.producerSettingsStore.load().defaultPlaybackRate
        )
    }

    func makeMIDIEditorViewModel(session: ProjectMIDISession) -> MIDIEditorViewModel {
        MIDIEditorViewModel(
            session: session,
            documentService: services.midiDocumentService,
            controllerMonitor: services.midiControllerMonitor
        )
    }
}
