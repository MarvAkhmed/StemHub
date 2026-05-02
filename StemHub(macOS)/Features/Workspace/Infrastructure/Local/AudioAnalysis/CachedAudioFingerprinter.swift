//
//  CachedAudioFingerprinter.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

import Foundation

struct CachedAudioFingerprinter<Base: AudioFingerprinting>: AudioFingerprinting
    where Base.Fingerprint == BasicAudioFingerprint
{
    typealias Fingerprint = BasicAudioFingerprint

    private let base: Base
    private let cache: FileProcessingCacheActor<BasicAudioFingerprint>

    init(
        base: Base,
        cache: FileProcessingCacheActor<BasicAudioFingerprint> = FileProcessingCacheActor()
    ) {
        self.base = base
        self.cache = cache
    }

    nonisolated func fingerprint(for url: URL) async throws -> BasicAudioFingerprint {
        let standardizedURL = url.standardizedFileURL
        let key = try FileProcessingCacheKeyResolver.key(for: standardizedURL)
        let base = base

        return try await cache.result(for: key) {
            try await base.fingerprint(for: standardizedURL)
        }
    }
}
