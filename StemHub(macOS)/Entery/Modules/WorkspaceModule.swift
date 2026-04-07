//
//  WorkspaceModule.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

@MainActor
final class WorkspaceModule {
    // MARK: - Dependencies
    private let persistence: ProjectPersistenceStrategy
    private let bookmark: BookmarkStrategy
    private let fileScanner: FileScannerStrategy
    private let diffEngine: DiffEngineStrategy
    private let posterEncoder: PosterEncoderStrategy
    private let network: ProjectNetworkStrategy
    private let authService: AuthServiceProtocol
    
    // MARK: - Services
    private let syncService: ProjectSyncService
    private let versionService: ProjectVersionService
    private let commitStorage: LocalCommitService
    private let fileService: ProjectFileService
    
    // MARK: - Init
    init(authService: AuthServiceProtocol? = nil) {
        // Initialize strategies
        self.persistence = DefaultProjectPersistenceStrategy()
        self.bookmark = DefaultBookmarkStrategy()
        self.fileScanner = DefaultFileScannerStrategy()
        self.diffEngine = DefaultDiffEngineStrategy()
        self.posterEncoder = PosterEncoderService()
        self.network = DefaultProjectNetworkStrategy()
        
        // Initialize auth service - if not provided, create a new instance
        // AuthService.init is @MainActor, so we need to use a nonisolated approach
        // Since we're already on MainActor due to @MainActor on the class, this is fine
        self.authService = authService ?? AuthService()
        
        // Initialize services
        self.syncService = DefaultProjectSyncService(
            syncOrchestrator: SyncOrchestrator(),
            network: self.network,
            persistence: self.persistence
        )
        self.versionService = DefaultProjectVersionService(
            network: self.network,
            firestoreVersionStrategy: DefaultFirestoreVersionStrategy()
        )
        self.commitStorage = DefaultLocalCommitService()
        self.fileService = DefaultProjectFileService(persistence: self.persistence)
    }
    
    // MARK: - Factory Methods
    
    func makeProjectCreationService() -> ProjectCreationServiceProtocol {
        ProjectCreationService(
            network: network,
            persistence: persistence,
            bookmark: bookmark,
            posterEncoder: posterEncoder
        )
    }
    
    func makeCommitStorage() -> LocalCommitService {
        commitStorage
    }
    
    func makeCommitApplier(commitStorage: LocalCommitService) -> CommitApplicationStrategy {
        DefaultCommitApplicationStrategy(
            network: network,
            commitStorage: commitStorage,
            diffEngine: diffEngine
        )
    }
    
    func makeWorkspaceViewModel() -> WorkspaceViewModel {
        WorkspaceViewModel(
            authService: authService,
            persistenceStrategy: persistence,
            networkStrategy: network,
            syncStrategy: syncService,
            bookmarkStrategy: bookmark
        )
    }
    
    func makeProjectDetailViewModel(project: Project, localState: LocalProjectState) -> ProjectDetailViewModel {
        ProjectDetailViewModel(
            project: project,
            localState: localState,
            authService: authService,
            syncService: syncService,
            versionService: versionService,
            commitStorage: commitStorage,
            fileService: fileService,
            persistence: persistence,
            network: network,
            bookmark: bookmark,
            fileScanner: fileScanner
        )
    }
    
    // MARK: - Service Getters
    
    func getSyncService() -> ProjectSyncService {
        syncService
    }
    
    func getVersionService() -> ProjectVersionService {
        versionService
    }
    
    func getCommitStorage() -> LocalCommitService {
        commitStorage
    }
    
    func getFileService() -> ProjectFileService {
        fileService
    }
    
    func getAuthService() -> AuthServiceProtocol {
        authService
    }
}
