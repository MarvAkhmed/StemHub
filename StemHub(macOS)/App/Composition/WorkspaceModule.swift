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
            workspaceStateService: services.workspaceStateService,
            commitWorkflowService: services.projectCommitWorkflowService,
            sectionFilter: services.workspaceSectionFilter,
            posterImageProvider: services.projectPosterService
        )
    }

    func makeMainAppShellView(authVM: AuthViewModel) -> MainAppShellView {
        MainAppShellView(
            authVM: authVM,
            module: self,
            workspaceVM: makeWorkspaceViewModel(),
            shellViewModel: makeShellViewModel(),
            notificationsViewModel: makeNotificationsViewModel(),
            profileViewModel: makeProfileViewModel(),
            settingsViewModel: makeSettingsViewModel()
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
        let playbackPreparer = DefaultAudioPlaybackPreparer()

        return ProjectDetailViewModel(
            project: project,
            dependencies: ProjectDetailViewModelDependencies(
                authService: dependencies.authService,
                collaborationService: services.collaborationService,
                projectPosterService: services.projectPosterService,
                detailWorkspaceService: services.projectDetailWorkspaceService,
                versionWorkflowService: services.projectVersionWorkflowService,
                commentWorkflowService: services.projectCommentWorkflowService,
                timestampedCommentService: services.timestampedCommentService,
                fileWorkflowService: services.projectFileWorkflowService,
                commitWorkflowService: services.projectCommitWorkflowService,
                branchWorkflowService: services.projectBranchWorkflowService,
                fileTypeProvider: services.fileTypeProvider,
                midiSessionResolver: services.midiSessionResolver,
                folderPicker: pickerService,
                audioPicker: pickerService,
                imagePicker: pickerService,
                audioPlaybackPreparer: playbackPreparer,
                audioPlaybackServiceFactory: WorkspaceAudioPlaybackServiceFactory(
                    playbackPreparer: playbackPreparer
                ),
                defaultPlaybackRate: dependencies.producerSettingsStore.load().defaultPlaybackRate
            )
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

@MainActor
private struct WorkspaceAudioPlaybackServiceFactory: AudioPlaybackServiceMaking {
    let playbackPreparer: AudioPlaybackPreparing

    func makeAudioPlaybackService(defaultPlaybackRate: Double) -> AudioPlaybackServicing {
        AudioPlaybackService(
            controller: AVAudioPlaybackController(
                playbackPreparer: playbackPreparer,
                defaultPlaybackRate: defaultPlaybackRate
            )
        )
    }
}
