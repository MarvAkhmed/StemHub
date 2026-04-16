//
//  WorkspaceModule.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

@MainActor
final class WorkspaceModule {

    // MARK: - Repositories (Firestore implementations)
    private let bandRepository: BandRepository
    private let projectRepository: ProjectRepository
    private let versionRepository: VersionRepository
    private let branchRepository: BranchRepository
    private let remoteSnapshotRepository: RemoteSnapshotRepository
    private let blobRepository: BlobRepository
    private let commitRepository: CommitRepository

    // MARK: - Strategies & Stores
    private let stateStore: ProjectStateStore
    private let bookmarkStrategy: BookmarkStrategy
    private let fileScanner: FileScanner
    private let diffEngine: DiffEngineStrategy
    private let posterEncoder: PosterEncoding

    // MARK: - Services
    private let workspaceLoader: WorkspaceLoaderServiceProtocol
    private let projectCreation: ProjectCreationServiceProtocol
    private let syncOrchestrator: SyncOrchestrator
    private let syncService: ProjectSyncService
    private let versionService: ProjectVersionService
    private let localCommitStore: LocalCommitStore
    private let folderService: ProjectFolderService

    // MARK: - Auth
    private let authService: AuthServiceProtocol

    // MARK: - Init
    init(authService: AuthServiceProtocol? = nil) {
        // Repositories
        self.bandRepository = FirestoreBandRepository()
        self.projectRepository = FirestoreProjectRepository()
        self.versionRepository = DefaultVersionRepository()
        self.branchRepository = DefaultBranchRepository()
        self.remoteSnapshotRepository = DefaultRemoteSnapshotRepository()
        self.blobRepository = DefaultBlobRepository()
        self.commitRepository = DefaultCommitRepository()

        // Strategies & Stores
        self.stateStore = UserDefaultsProjectStateStore()
        self.bookmarkStrategy = DefaultBookmarkStrategy()
        self.fileScanner = LocalFileScanner()
        self.diffEngine = DefaultDiffEngineStrategy()
        self.posterEncoder = PosterEncoderService()

        // Auth
        self.authService = authService ?? AuthService()

        // Services
        self.workspaceLoader = WorkspaceLoaderService(
            bandRepository: bandRepository,
            projectRepository: projectRepository
        )

        self.projectCreation = ProjectCreationService(
            bandRepository: bandRepository,
            projectRepository: projectRepository,
            stateStore: stateStore,
            bookmarkStrategy: bookmarkStrategy,
            posterEncoder: posterEncoder
        )

        self.syncOrchestrator = SyncOrchestrator(
            scanStrategy: fileScanner,
            diffStrategy: diffEngine,
            commitRepository: commitRepository,
            fileUploadStrategy: FileUploadService(),
            branchRepository: branchRepository,
            versionRepository: versionRepository,
            blobRepository: blobRepository
        )

        self.syncService = DefaultProjectSyncService(
            syncOrchestrator: syncOrchestrator,
            branchRepository: branchRepository,
            remoteSnapshotRepository: remoteSnapshotRepository,
            stateStore: stateStore,
            diffEngine: diffEngine
        )

        self.versionService = DefaultProjectVersionService(
            versionRepository: versionRepository
        )

        self.localCommitStore = DefaultLocalCommitStore()

        self.folderService = DefaultProjectFolderService(
            stateStore: stateStore,
            bookmarkStrategy: bookmarkStrategy,
            scanner: fileScanner
        )
    }

    // MARK: - Factory Methods

    func makeWorkspaceViewModel() -> WorkspaceViewModel {
        WorkspaceViewModel(
            authService: authService,
            workspaceLoader: workspaceLoader,
            projectCreation: projectCreation,
            syncService: syncService,
            stateStore: stateStore,
            bookmarkStrategy: bookmarkStrategy
        )
    }

    func makeProjectDetailViewModel(project: Project) -> ProjectDetailViewModel {
        // Load current sync state for the project
//        let syncState = stateStore.syncState(for: project.id)

        return ProjectDetailViewModel(
            project: project,
            authService: authService,
            syncService: syncService,
            versionService: versionService,
            localCommitStore: localCommitStore,
            folderService: folderService,
            stateStore: stateStore,
            branchRepository: branchRepository,
            projectRepository: projectRepository,
            bookmarkStrategy: bookmarkStrategy,
            fileScanner: fileScanner
        )
    }

    // MARK: - Service Getters (for convenience / testing)

    func getSyncService() -> ProjectSyncService {
        syncService
    }

    func getVersionService() -> ProjectVersionService {
        versionService
    }

    func getLocalCommitStore() -> LocalCommitStore {
        localCommitStore
    }

    func getFolderService() -> ProjectFolderService {
        folderService
    }

    func getAuthService() -> AuthServiceProtocol {
        authService
    }
}
