//
//  WorkspaceDependencyContainer.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation
import FirebaseFirestore

/// The composition root for the entire Workspace feature.
///
/// ## Responsibility
/// `WorkspaceDependencyContainer` is the single place in the application
/// where concrete types are instantiated and wired together. All other types
/// receive their dependencies through `init` parameters — they never construct
/// dependencies themselves.
///
/// ## What is built here and why
/// The following concrete types are instantiated internally because they are
/// *leaf types* (no injectable dependencies of their own) or because this
/// container IS their composition root:
///
/// - `DefaultAudioPCMFormatFactory` — leaf, no deps.
/// - `DefaultAudioConverterFactory` — leaf, no deps.
/// - `DefaultAudioPCMBufferFactory` — leaf, no deps.
/// - `DefaultAudioConverterRunner`  — leaf, no deps.
/// - `DefaultAudioConversionStatusHandler` — leaf, no deps.
/// - `DefaultAudioSampleExtractor`  — leaf, no deps.
/// - `DefaultDSPFacadeBuilder`      — leaf, no deps.
/// - `MelFilterbankBuilder`         — leaf, no deps.
/// - `DCTProcessor`                 — leaf, no deps.
/// - `ChromaProcessor`              — leaf, no deps.
/// - `SpectralFeatureExtractor`     — leaf, no deps.
/// - `BasicAudioFeatureExtractorFactory` — leaf, no deps.
/// - `UniformTypeMediaFileDetector` — leaf, no deps.
///
/// Non-leaf types (`DefaultAVFoundationAudioPCMDecoder`, `AVFoundationPCMHasher`,
/// `BasicAudioFingerprinter`, etc.) receive all their deps via init. Their
/// internal caches (`FileProcessingCacheActor`) are constructed here and
/// injected explicitly — never default-constructed inside the non-leaf type.
///
/// LAW-D1: No singletons; no static stored properties; no global state.
/// LAW-D2: Default init parameters are only used for leaf types.
struct WorkspaceDependencyContainer {
    
    // MARK: - Remote repositories
    let bandRepository:             BandRepository
    let bandInvitationRepository:   BandInvitationRepository
    let projectRepository:          ProjectRepository
    let userRepository:             UserRepository
    let commentRepository:          CommentRepository
    let versionRepository:          VersionRepository
    let branchRepository:           BranchRepository
    let remoteSnapshotRepository:   RemoteSnapshotRepository
    let blobRepository:             BlobRepository
    let commitRepository:           CommitRepository
    let fileTransferStrategy:       any RemoteFileTransferStrategy
    & RemoteBlobStorage
    & RemoteBlobByteCleaning
    
    // MARK: - Local state
    let stateStore:                 ProjectStateStore
    let bookmarkStrategy:           BookmarkStrategy
    let producerSettingsStore:      any ProducerSettingsStoring
    let localCommitStore:           LocalCommitStore
    
    // MARK: - File system
    let fileScanner:                FileScannerStrategy
    let fileHasher:                 FileHashing
    let folderSnapshotHasher:       FolderSnapshotHashing
    
    // MARK: - Audio analysis
    let pcmHasher:                  any PCMHashing
    let audioFingerprinter:         CachedAudioFingerprinter<BasicAudioFingerprinter>
    let audioSimilarityComparer:    BasicAudioSimilarityComparer
    let mediaFileDetector:          any AudioFileProviding & MIDIFileProviding
    
    // MARK: - Snapshot / diff / checkout
    let localFileSnapshotProvider:  LocalFileSnapshotProviding
    let localCommitSnapshotPreparer: LocalCommitSnapshotPreparing
    let workingTreeCheckout:        WorkingTreeCheckingOut
    let diffEngine:                 DiffEngineStrategy
    
    // MARK: - Misc
    let posterEncoder:              PosterEncoding
    let authService:                AuthServiceProtocol
    
    // MARK: - Init
    init(authService: AuthServiceProtocol, remoteBackendKind: RemoteBackendKind = .firebase) {
        // ── Remote backend ────────────────────────────────────────────────
        let db = Firestore.firestore()
        
        let remoteRepositories = RemoteBackendFactory(backendKind: remoteBackendKind,db: db).makeRemoteRepositories()
        
        bandRepository           = remoteRepositories.bandRepository
        bandInvitationRepository = FirestoreBandInvitationRepository(db: db)
        projectRepository        = remoteRepositories.projectRepository
        userRepository           = remoteRepositories.userRepository
        commentRepository        = remoteRepositories.commentRepository
        versionRepository        = remoteRepositories.versionRepository
        branchRepository         = remoteRepositories.branchRepository
        remoteSnapshotRepository = remoteRepositories.remoteSnapshotRepository
        blobRepository           = remoteRepositories.blobRepository
        commitRepository         = remoteRepositories.commitRepository
        fileTransferStrategy     = remoteRepositories.blobStorage
        
        // ── Local state stores ────────────────────────────────────────────
        stateStore           = UserDefaultsProjectStateStore()
        bookmarkStrategy     = DefaultBookmarkStrategy()
        producerSettingsStore = UserDefaultsProducerSettingsStore()
        let builtLocalCommitStore = DefaultLocalCommitStore()
        localCommitStore = builtLocalCommitStore
        
        // ── File system ───────────────────────────────────────────────────
        let localFileScanner     = LocalFileScanner()
        let builtFileHasher      = CachedFileHasher(base: SHA256FileHasher())
        let builtFolderHasher    = FolderSnapshotHasher(scanner: localFileScanner, fileHasher: builtFileHasher)
        
        fileScanner           = localFileScanner
        fileHasher            = builtFileHasher
        folderSnapshotHasher  = builtFolderHasher
        
        // ── Audio decoding stack ──────────────────────────────────────────
        // Leaf types — constructed here as they have no injectable dependencies.
        let formatFactory    = DefaultAudioPCMFormatFactory()
        let converterFactory = DefaultAudioConverterFactory()
        let bufferFactory    = DefaultAudioPCMBufferFactory()
        let converterRunner  = DefaultAudioConverterRunner()
        let statusHandler    = DefaultAudioConversionStatusHandler()
        let sampleExtractor  = DefaultAudioSampleExtractor()
        
        let contextBuilder = DefaultAudioDecodingContextBuilder(outputFrameCapacity: 4_096,
                                                                formatFactory:       formatFactory,
                                                                converterFactory:    converterFactory
        )
        
        let decoder = DefaultAVFoundationAudioPCMDecoder(contextBuilder:  contextBuilder,
                                                         bufferFactory:   bufferFactory,
                                                         converterRunner: converterRunner,
                                                         sampleExtractor: sampleExtractor,
                                                         statusHandler:   statusHandler
        )
        
        // ── PCM hasher ────────────────────────────────────────────────────
        // The base hasher requires a `decoder` and `targetSampleRate` — both
        // injected explicitly. The cache is constructed here and injected into
        // the decorator; it is NOT default-constructed inside `CachedPCMHasher`.
        let basePCMHasher = AVFoundationPCMHasher(
            targetSampleRate: AudioFingerprintConfiguration.makeBasic().targetSampleRate,
            decoder:          decoder
        )
        let pcmHasherCache = FileProcessingCacheActor<String>()
        pcmHasher = CachedPCMHasher(base: basePCMHasher, cache: pcmHasherCache)
        
        // ── Audio fingerprinter ───────────────────────────────────────────
        // `BasicAudioFingerprinter` requires `configuration`, `decoder`, and
        // `featureExtractorFactory` — all injected. The cache is constructed
        // here and injected into `CachedAudioFingerprinter`.
        let fingerprintConfiguration = AudioFingerprintConfiguration.makeBasic()
        let featureExtractorFactory  = BasicAudioFeatureExtractorFactory()
        
        let baseFingerprinter = BasicAudioFingerprinter(
            configuration:          fingerprintConfiguration,
            decoder:                decoder,
            featureExtractorFactory: featureExtractorFactory
        )
        let fingerprintCache = FileProcessingCacheActor<BasicAudioFingerprint>()
        audioFingerprinter   = CachedAudioFingerprinter(
            base:  baseFingerprinter,
            cache: fingerprintCache
        )
        
        // ── Similarity comparer ───────────────────────────────────────────
        audioSimilarityComparer = BasicAudioSimilarityComparer()
        
        // ── Media file detector ───────────────────────────────────────────
        mediaFileDetector = UniformTypeMediaFileDetector()
        
        // ── Local snapshot / diff / checkout ─────────────────────────────
        let builtLocalFileSnapshotProvider = LocalFileSnapshotProvider(
            scanner:    localFileScanner,
            fileHasher: builtFileHasher
        )
        localFileSnapshotProvider = builtLocalFileSnapshotProvider
        
        localCommitSnapshotPreparer = DefaultLocalCommitSnapshotPreparer(
            localFileSnapshotProvider: builtLocalFileSnapshotProvider,
            localCommitStore:          builtLocalCommitStore
        )
        
        let builtDiffEngine = DefaultDiffEngineStrategy()
        diffEngine = builtDiffEngine
        
        workingTreeCheckout = LocalWorkingTreeCheckoutService(
            localFileSnapshotProvider: builtLocalFileSnapshotProvider,
            diffStrategy:              builtDiffEngine,
            fileTransferStrategy:      remoteRepositories.blobStorage
        )
        
        // ── Misc ──────────────────────────────────────────────────────────
        posterEncoder    = PosterEncoderService()
        self.authService = authService
    }
}
