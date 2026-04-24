//
//  WorkspaceServiceContainer.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

struct WorkspaceServiceContainer {
    let workspaceLoader: WorkspaceLoaderServiceProtocol
    let workspaceCatalogService: WorkspaceProjectCatalogProviding
    let projectCreation: ProjectCreationServiceProtocol
    let projectDeletionService: ProjectDeletionServiceProtocol
    let syncOrchestrator: SyncOrchestrator
    let syncService: ProjectSyncService
    let versionService: ProjectVersionService
    let folderService: any ProjectFolderService
    let branchService: ProjectBranchServiceProtocol
    let collaborationService: ProjectCollaborationServiceProtocol
    let commentService: ProjectCommentServiceProtocol
    let invitationService: BandInvitationServiceProtocol
    let releaseCatalogService: ReleaseCatalogProviding
    let versionApprovalService: ProjectVersionApprovalServiceProtocol
    let midiDocumentService: MIDIDocumentEditing
    let midiSessionResolver: ProjectMIDISessionResolving
    let midiControllerMonitor: MIDIControllerMonitoring

    init(dependencies: WorkspaceDependencyContainer) {
        workspaceLoader = WorkspaceLoaderService(
            bandRepository: dependencies.bandRepository,
            projectRepository: dependencies.projectRepository
        )

        versionService = DefaultProjectVersionService(
            versionRepository: dependencies.versionRepository
        )

        workspaceCatalogService = WorkspaceProjectCatalogService(
            workspaceLoader: workspaceLoader,
            versionService: versionService
        )

        projectCreation = ProjectCreationService(
            bandRepository: dependencies.bandRepository,
            projectRepository: dependencies.projectRepository,
            stateStore: dependencies.stateStore,
            bookmarkStrategy: dependencies.bookmarkStrategy,
            posterEncoder: dependencies.posterEncoder
        )

        projectDeletionService = ProjectDeletionService(
            projectRepository: dependencies.projectRepository,
            stateStore: dependencies.stateStore,
            localCommitStore: dependencies.localCommitStore
        )

        syncOrchestrator = SyncOrchestrator(
            scanStrategy: dependencies.fileScanner,
            diffStrategy: dependencies.diffEngine,
            commitRepository: dependencies.commitRepository,
            fileUploadStrategy: FileUploadService(),
            branchRepository: dependencies.branchRepository,
            versionRepository: dependencies.versionRepository,
            blobRepository: dependencies.blobRepository
        )

        syncService = DefaultProjectSyncService(
            syncOrchestrator: syncOrchestrator,
            branchRepository: dependencies.branchRepository,
            remoteSnapshotRepository: dependencies.remoteSnapshotRepository,
            stateStore: dependencies.stateStore,
            diffEngine: dependencies.diffEngine
        )

        folderService = DefaultProjectFolderService(
            stateStore: dependencies.stateStore,
            bookmarkStrategy: dependencies.bookmarkStrategy,
            scanner: dependencies.fileScanner
        )

        branchService = ProjectBranchService(
            branchRepository: dependencies.branchRepository,
            versionRepository: dependencies.versionRepository
        )

        invitationService = BandInvitationService(
            invitationRepository: dependencies.bandInvitationRepository,
            bandRepository: dependencies.bandRepository,
            userRepository: dependencies.userRepository
        )

        collaborationService = ProjectCollaborationService(
            bandRepository: dependencies.bandRepository,
            userRepository: dependencies.userRepository,
            invitationService: invitationService
        )

        commentService = ProjectCommentService(
            commentRepository: dependencies.commentRepository
        )

        releaseCatalogService = ReleaseCatalogService(
            workspaceLoader: workspaceLoader,
            versionRepository: dependencies.versionRepository
        )

        versionApprovalService = ProjectVersionApprovalService(
            versionRepository: dependencies.versionRepository
        )

        midiDocumentService = CoreAudioMIDIDocumentService()
        midiSessionResolver = DefaultProjectMIDISessionResolver(
            folderService: folderService
        )
        midiControllerMonitor = CoreMIDIControllerMonitor()
    }
}
