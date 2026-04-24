//
//  WorkspaceDependencyContainer.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation
import FirebaseFirestore

struct WorkspaceDependencyContainer {
    let bandRepository: BandRepository
    let bandInvitationRepository: BandInvitationRepository
    let projectRepository: ProjectRepository
    let userRepository: UserRepository
    let commentRepository: CommentRepository
    let versionRepository: VersionRepository
    let branchRepository: BranchRepository
    let remoteSnapshotRepository: RemoteSnapshotRepository
    let blobRepository: BlobRepository
    let commitRepository: CommitRepository
    let stateStore: ProjectStateStore
    let bookmarkStrategy: BookmarkStrategy
    let fileScanner: FileScanner
    let diffEngine: DiffEngineStrategy
    let posterEncoder: PosterEncoding
    let localCommitStore: LocalCommitStore
    let producerSettingsStore: any ProducerSettingsStoring
    let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        FirebaseRuntimeBootstrap.ensureConfigured()

        let firestore = Firestore.firestore()
        let branchStrategy = DefaultFirestoreBranchStrategy(db: firestore)
        let versionStrategy = DefaultFirestoreVersionStrategy(db: firestore)
        let blobStrategy = DefaultFirestoreBlobStrategy(db: firestore)
        let fileUploadStrategy = FileUploadService()
        let commitStorageStrategy = DefaultCommitStorageStrategy(
            db: firestore,
            uploadStrategy: fileUploadStrategy,
            blobStrategy: blobStrategy,
            branchStrategy: branchStrategy
        )
        let remoteSnapshotStrategy = DefaultProjectNetworkStrategy(db: firestore)

        bandRepository = FirestoreBandRepository()
        bandInvitationRepository = FirestoreBandInvitationRepository()
        projectRepository = FirestoreProjectRepository()
        userRepository = FirestoreUserRepository()
        commentRepository = FirestoreCommentRepository()
        versionRepository = DefaultVersionRepository(strategy: versionStrategy)
        branchRepository = DefaultBranchRepository(strategy: branchStrategy)
        remoteSnapshotRepository = DefaultRemoteSnapshotRepository(network: remoteSnapshotStrategy)
        blobRepository = DefaultBlobRepository(strategy: blobStrategy)
        commitRepository = DefaultCommitRepository(strategy: commitStorageStrategy)
        stateStore = UserDefaultsProjectStateStore()
        bookmarkStrategy = DefaultBookmarkStrategy()
        fileScanner = LocalFileScanner()
        diffEngine = DefaultDiffEngineStrategy()
        posterEncoder = PosterEncoderService()
        localCommitStore = DefaultLocalCommitStore()
        producerSettingsStore = UserDefaultsProducerSettingsStore()
        self.authService = authService
    }
}
