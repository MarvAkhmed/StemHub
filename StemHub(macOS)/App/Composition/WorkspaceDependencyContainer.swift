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
    let fileTransferStrategy: any RemoteFileTransferStrategy & RemoteBlobStorage & RemoteBlobByteCleaning
    let stateStore: ProjectStateStore
    let bookmarkStrategy: BookmarkStrategy
    let fileScanner: FileScannerStrategy
    let fileHasher: FileHashing
    let folderSnapshotHasher: FolderSnapshotHashing
    let pcmHasher: any PCMHashing
    let audioFingerprinter: CachedAudioFingerprinter<BasicAudioFingerprinter>
    let audioSimilarityComparer: BasicAudioSimilarityComparer
    let mediaFileDetector: any AudioFileDetecting & MIDIFileDetecting
    let localFileSnapshotProvider: LocalFileSnapshotProviding
    let localCommitSnapshotPreparer: LocalCommitSnapshotPreparing
    let workingTreeCheckout: WorkingTreeCheckingOut
    let diffEngine: DiffEngineStrategy
    let posterEncoder: PosterEncoding
    let localCommitStore: LocalCommitStore
    let producerSettingsStore: any ProducerSettingsStoring
    let authService: AuthServiceProtocol
   
    
    init(
        authService: AuthServiceProtocol,
        remoteBackendKind: RemoteBackendKind = .firebase
    ) {
        let db = Firestore.firestore()
        
        let remoteRepositories = RemoteBackendFactory(backendKind: remoteBackendKind,
                                                      db: db)
            .makeRemoteRepositories()
        
        bandRepository = remoteRepositories.bandRepository
        bandInvitationRepository = FirestoreBandInvitationRepository(db: db)
        projectRepository = remoteRepositories.projectRepository
        userRepository = remoteRepositories.userRepository
        commentRepository = remoteRepositories.commentRepository
        versionRepository = remoteRepositories.versionRepository
        branchRepository = remoteRepositories.branchRepository
        remoteSnapshotRepository = remoteRepositories.remoteSnapshotRepository
        blobRepository = remoteRepositories.blobRepository
        commitRepository = remoteRepositories.commitRepository
        fileTransferStrategy = remoteRepositories.blobStorage
        let localFileScanner = LocalFileScanner()
        let fileHasher = CachedFileHasher(base: SHA256FileHasher())
        let folderSnapshotHasher = FolderSnapshotHasher(
            scanner: localFileScanner,
            fileHasher: fileHasher
        )
        let pcmHasher = CachedPCMHasher(base: AVFoundationPCMHasher())
        let audioFingerprinter = CachedAudioFingerprinter(base: BasicAudioFingerprinter())
        let audioSimilarityComparer = BasicAudioSimilarityComparer()
        let mediaFileDetector = UniformTypeMediaFileDetector()
        let localFileSnapshotProvider = LocalFileSnapshotProvider(
            scanner: localFileScanner,
            fileHasher: fileHasher
        )
        let localCommitStore = DefaultLocalCommitStore()
        let diffEngine = DefaultDiffEngineStrategy()
        
        stateStore = UserDefaultsProjectStateStore()
        bookmarkStrategy = DefaultBookmarkStrategy()
        fileScanner = localFileScanner
        self.fileHasher = fileHasher
        self.folderSnapshotHasher = folderSnapshotHasher
        self.pcmHasher = pcmHasher
        self.audioFingerprinter = audioFingerprinter
        self.audioSimilarityComparer = audioSimilarityComparer
        self.mediaFileDetector = mediaFileDetector
        self.localFileSnapshotProvider = localFileSnapshotProvider
        localCommitSnapshotPreparer = DefaultLocalCommitSnapshotPreparer(
            localFileSnapshotProvider: localFileSnapshotProvider,
            localCommitStore: localCommitStore
        )
        workingTreeCheckout = LocalWorkingTreeCheckoutService(
            localFileSnapshotProvider: localFileSnapshotProvider,
            diffStrategy: diffEngine,
            fileTransferStrategy: remoteRepositories.blobStorage
        )
        self.diffEngine = diffEngine
        posterEncoder = PosterEncoderService()
        self.localCommitStore = localCommitStore
        producerSettingsStore = UserDefaultsProducerSettingsStore()
        self.authService = authService
    }
}
