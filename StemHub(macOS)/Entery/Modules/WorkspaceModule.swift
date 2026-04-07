//
//  WorkspaceModule.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

@MainActor
struct WorkspaceModule {
    private let persistence: ProjectPersistenceStrategy
    private let bookmark: BookmarkStrategy
    private let fileScanner: FileScannerStrategy
    private let diffEngine: DiffEngineStrategy
    private let posterEncoder: PosterEncoderStrategy
    private let network: ProjectNetworkStrategy
    
    init() {
        self.persistence = DefaultProjectPersistenceStrategy()
        self.bookmark = DefaultBookmarkStrategy()
        self.fileScanner = DefaultFileScannerStrategy()
        self.diffEngine = DefaultDiffEngineStrategy()
        self.posterEncoder = PosterEncoderService()
        self.network = DefaultProjectNetworkStrategy()
    }
    
    func makeProjectCreationService() -> ProjectCreationServiceProtocol {
        ProjectCreationService(
            network: network,
            persistence: persistence,
            bookmark: bookmark,
            posterEncoder: posterEncoder
        )
    }
    
    func makeCommitStorage() -> LocalCommitStorageStrategy {
        DefaultLocalCommitStorageStrategy()
    }
    
    
    func makeCommitApplier(commitStorage: LocalCommitStorageStrategy) -> CommitApplicationStrategy {
        DefaultCommitApplicationStrategy(
            network: network,
            commitStorage: commitStorage,
            diffEngine: diffEngine
        )
    }
    
    func makeWorkspaceViewModel(currentUser: User) -> WorkspaceViewModel {
        WorkspaceViewModel(currentUser: currentUser)
    }
    
    func makeProjectDetailViewModel(project: Project,
                                    localState: LocalProjectState,
                                    currentUserID: String) -> ProjectDetailViewModel {
        ProjectDetailViewModel(
            project: project,
            localState: localState,
            currentUserID: currentUserID,
            persistence: persistence,
            network: network,
            bookmark: bookmark,
            fileScanner: fileScanner
        )
    }
    
//    func makeBookmarkResolver() -> BookmarkResolverStrategy {
//        BookmarkResolverService(
//            persistence: persistence,
//            bookmark: bookmark
//        )
//    }
//    
//    func makeFileTreeBuilder() -> FileTreeBuilderProtocol {
//        FileTreeBuilderService()
//    }
}
