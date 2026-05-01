//
//  CachedAudioFingerprinter.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct CachedAudioFingerprinter<Base: AudioFingerprinting>: AudioFingerprinting {
    typealias Fingerprint = Base.Fingerprint

    private let base: Base
    private let cache: FileProcessingCacheActor<Fingerprint>

    init(
        base: Base,
        cache: FileProcessingCacheActor<Fingerprint> = FileProcessingCacheActor()
    ) {
        self.base = base
        self.cache = cache
    }

    nonisolated func fingerprint(for url: URL) async throws -> Fingerprint {
        let standardizedURL = url.standardizedFileURL
        let key = try FileProcessingCacheKeyResolver.key(for: standardizedURL)
        let base = base

        return try await cache.result(for: key) {
            Task {
                try await base.fingerprint(for: standardizedURL)
            }
        }
    }
}
