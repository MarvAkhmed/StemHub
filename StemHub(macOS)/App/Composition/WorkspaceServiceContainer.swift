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
    let workspaceSectionFilter: WorkspaceSectionFiltering
    let projectRemoteBlobCleaner: ProjectRemoteBlobCleaning
    let pushCommitService: CommitPushing
    let syncOrchestrator: SyncOrchestrator
    let syncService: ProjectSyncService
    let versionService: ProjectVersionService
    let folderService: any ProjectFolderService
    let localWorkspaceService: ProjectLocalWorkspaceService
    let workspaceStateService: ProjectWorkspaceStateManaging
    let projectPosterService: ProjectPosterManaging
    let projectRemoteStateService: ProjectRemoteWorkspaceStateManaging
    let projectDetailWorkspaceService: ProjectDetailWorkspaceLoading
    let projectCommitWorkflowService: ProjectCommitWorkflowing
    let projectBranchWorkflowService: ProjectDetailBranchWorkflowing
    let projectFileWorkflowService: ProjectFileWorkflowing
    let projectCommentWorkflowService: ProjectCommentWorkflowing
    let timestampedCommentService: TimestampedCommentServing
    let projectVersionWorkflowService: ProjectVersionWorkflowing
    let fileTypeProvider: ProjectFileTypeProviding
    let audioIdentityAnalysisService: AudioIdentityAnalysisService<CachedAudioFingerprinter<BasicAudioFingerprinter>>
    let audioComparisonService: AudioComparisonService<BasicAudioSimilarityComparer>
    let branchService: ProjectBranchServiceProtocol
    let collaborationService: ProjectCollaborationServiceProtocol
    let commentService: ProjectCommentServiceProtocol
    let projectCommentFilter: ProjectCommentFiltering
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

        projectRemoteBlobCleaner = ProjectRemoteBlobCleanupService(
            blobStoragePathListing: dependencies.projectRepository,
            blobByteCleaner: dependencies.fileTransferStrategy
        )

        projectDeletionService = ProjectDeletionService(
            projectRepository: dependencies.projectRepository,
            remoteBlobCleaner: projectRemoteBlobCleaner,
            stateStore: dependencies.stateStore,
            localCommitStore: dependencies.localCommitStore
        )

        workspaceSectionFilter = DefaultWorkspaceSectionFilter()

        pushCommitService = PushCommitService(
            versionRepository: dependencies.versionRepository,
            commitRepository: dependencies.commitRepository,
            fileTransferStrategy: dependencies.fileTransferStrategy
        )

        syncOrchestrator = SyncOrchestrator(
            localCommitSnapshotPreparer: dependencies.localCommitSnapshotPreparer,
            commitPusher: pushCommitService,
            branchRepository: dependencies.branchRepository,
            versionRepository: dependencies.versionRepository,
            blobRepository: dependencies.blobRepository,
            workingTree: dependencies.workingTreeCheckout
        )

        syncService = DefaultProjectSyncService(
            syncOrchestrator: syncOrchestrator,
            branchRepository: dependencies.branchRepository,
            remoteSnapshotRepository: dependencies.remoteSnapshotRepository,
            stateStore: dependencies.stateStore
        )

        folderService = DefaultProjectFolderService(
            stateStore: dependencies.stateStore,
            bookmarkStrategy: dependencies.bookmarkStrategy,
            scanner: dependencies.fileScanner
        )

        localWorkspaceService = ProjectLocalWorkspaceService(
            folderService: folderService,
            localCommitStore: dependencies.localCommitStore
        )

        projectFileWorkflowService = ProjectFileWorkflowService(
            localWorkspace: localWorkspaceService
        )

        workspaceStateService = ProjectWorkspaceStateService(
            stateStore: dependencies.stateStore
        )

        fileTypeProvider = DefaultProjectFileTypeProvider(
            mediaFileDetector: dependencies.mediaFileDetector
        )

        audioIdentityAnalysisService = AudioIdentityAnalysisService(
            fileHasher: dependencies.fileHasher,
            pcmHasher: dependencies.pcmHasher,
            fingerprinter: dependencies.audioFingerprinter
        )

        audioComparisonService = AudioComparisonService(
            comparer: dependencies.audioSimilarityComparer
        )

        projectPosterService = ProjectPosterService(
            posterEncoder: dependencies.posterEncoder,
            projectRepository: dependencies.projectRepository
        )

        projectRemoteStateService = ProjectRemoteWorkspaceStateService(
            projectRepository: dependencies.projectRepository
        )

        branchService = ProjectBranchService(
            branchRepository: dependencies.branchRepository,
            versionRepository: dependencies.versionRepository
        )

        projectCommitWorkflowService = ProjectCommitWorkflowService(
            syncService: syncService,
            localWorkspace: localWorkspaceService,
            workspaceStateService: workspaceStateService
        )

        projectBranchWorkflowService = ProjectDetailBranchWorkflowService(
            branchService: branchService,
            localWorkspace: localWorkspaceService,
            syncService: syncService,
            workspaceStateService: workspaceStateService,
            remoteStateService: projectRemoteStateService
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

        projectDetailWorkspaceService = ProjectDetailWorkspaceService(
            branchService: branchService,
            localWorkspace: localWorkspaceService,
            workspaceStateService: workspaceStateService,
            collaborationService: collaborationService
        )

        commentService = ProjectCommentService(
            commentRepository: dependencies.commentRepository
        )

        projectCommentFilter = DefaultProjectCommentFilter()

        projectCommentWorkflowService = ProjectCommentWorkflowService(
            commentService: commentService,
            commentFilter: projectCommentFilter
        )

        timestampedCommentService = TimestampedCommentService(
            repository: dependencies.commentRepository
        )

        releaseCatalogService = ReleaseCatalogService(
            workspaceLoader: workspaceLoader,
            versionRepository: dependencies.versionRepository
        )

        versionApprovalService = ProjectVersionApprovalService(
            versionRepository: dependencies.versionRepository
        )

        projectVersionWorkflowService = ProjectVersionWorkflowService(
            versionService: versionService,
            versionApprovalService: versionApprovalService
        )

        midiDocumentService = CoreAudioMIDIDocumentService()
        midiSessionResolver = DefaultProjectMIDISessionResolver(
            folderService: folderService,
            fileTypeProvider: fileTypeProvider
        )
        midiControllerMonitor = CoreMIDIControllerMonitor()
    }
}
