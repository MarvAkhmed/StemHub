//
//  AudioIdentityAnalysisService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct AnalyzedAudioIdentity<Fingerprint: Sendable>: Sendable {
    let fileHash: String
    let pcmHash: String
    let fingerprint: Fingerprint
}

struct AnalyzedAudioFile<Fingerprint: Sendable>: Sendable {
    let url: URL
    let identity: AnalyzedAudioIdentity<Fingerprint>
}

protocol AudioIdentityAnalyzing: Sendable {
    associatedtype Fingerprint: Sendable

    func analyzeAudioFile(_ url: URL) async throws -> AnalyzedAudioIdentity<Fingerprint>
    func analyzeAudioFiles(_ urls: [URL]) async throws -> [AnalyzedAudioFile<Fingerprint>]
}

final class AudioIdentityAnalysisService<Fingerprinter: AudioFingerprinting>: AudioIdentityAnalyzing, @unchecked Sendable {
    typealias Fingerprint = Fingerprinter.Fingerprint

    private let fileHasher: any FileHashing
    private let pcmHasher: any PCMHashing
    private let fingerprinter: Fingerprinter
    private let cache: AudioAnalysisCacheActor<AnalyzedAudioIdentity<Fingerprint>>
    private let limiter: AnalysisLimiterActor

    init(
        fileHasher: any FileHashing,
        pcmHasher: any PCMHashing,
        fingerprinter: Fingerprinter,
        cache: AudioAnalysisCacheActor<AnalyzedAudioIdentity<Fingerprint>> = AudioAnalysisCacheActor(),
        limiter: AnalysisLimiterActor = AnalysisLimiterActor(maxConcurrent: 2)
    ) {
        self.fileHasher = fileHasher
        self.pcmHasher = pcmHasher
        self.fingerprinter = fingerprinter
        self.cache = cache
        self.limiter = limiter
    }

    func analyzeAudioFile(_ url: URL) async throws -> AnalyzedAudioIdentity<Fingerprint> {
        let fileHash = try await fileHasher.fileHash(for: url)
        let pcmHasher = pcmHasher
        let fingerprinter = fingerprinter
        let limiter = limiter

        return try await cache.result(for: fileHash) {
            Task {
                try await limiter.withSlot {
                    let pcmHash = try await pcmHasher.pcmHash(for: url)
                    let fingerprint = try await fingerprinter.fingerprint(for: url)

                    return AnalyzedAudioIdentity(
                        fileHash: fileHash,
                        pcmHash: pcmHash,
                        fingerprint: fingerprint
                    )
                }
            }
        }
    }

    func analyzeAudioFiles(_ urls: [URL]) async throws -> [AnalyzedAudioFile<Fingerprint>] {
        let uniqueURLs = await urls.uniqueStandardizedFileURLs()

        return try await withThrowingTaskGroup(
            of: (Int, AnalyzedAudioFile<Fingerprint>).self
        ) { group in
            for (index, url) in uniqueURLs.enumerated() {
                group.addTask { [self] in
                    let identity = try await analyzeAudioFile(url)
                    return (
                        index,
                        AnalyzedAudioFile(
                            url: url,
                            identity: identity
                        )
                    )
                }
            }

            var analyzedFiles: [(Int, AnalyzedAudioFile<Fingerprint>)] = []
            analyzedFiles.reserveCapacity(uniqueURLs.count)

            for try await analyzedFile in group {
                analyzedFiles.append(analyzedFile)
            }

            return analyzedFiles
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }


}

protocol AudioComparing: Sendable {
    associatedtype Fingerprint: Sendable

    func similarity(
        between lhs: Fingerprint,
        and rhs: Fingerprint
    ) throws -> Double
}

final class AudioComparisonService<Comparer: AudioSimilarityComparing>: AudioComparing, @unchecked Sendable {
    typealias Fingerprint = Comparer.Fingerprint

    private let comparer: Comparer

    init(comparer: Comparer) {
        self.comparer = comparer
    }

    func similarity(
        between lhs: Fingerprint,
        and rhs: Fingerprint
    ) throws -> Double {
        try comparer.similarity(between: lhs, and: rhs)
    }
}
