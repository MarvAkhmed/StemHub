//
//  CachedAudioFingerprinter.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Decorates any `AudioFingerprinting` implementation with file-level caching.
///
/// The cache key is derived from the file's inode and volume identifier via
/// `FileProcessingCacheKeyResolver` (LAW-K2). If a fingerprint for the same
/// inode already exists in the cache, it is returned immediately without
/// re-decoding.
///
/// LAW-K1: Pure decorator — zero domain logic added here.
/// LAW-D2: `cache` must be injected; `CachedAudioFingerprinter` is not a
///   leaf type (it wraps `Base`), so default-constructing the cache is
///   forbidden. The caller at the composition root decides cache lifetime.
struct CachedAudioFingerprinter<Base: AudioFingerprinting>: AudioFingerprinting {
    typealias Fingerprint = Base.Fingerprint

    // MARK: - Dependencies

    private let base:  Base
    private let cache: FileProcessingCacheActor<Fingerprint>

    // MARK: - Init

    /// - Parameters:
    ///   - base: The underlying fingerprinter to delegate cache misses to.
    ///   - cache: The shared cache actor. Must be injected; never default-constructed.
    init(base: Base, cache: FileProcessingCacheActor<Fingerprint>) {
        self.base  = base
        self.cache = cache
    }

    // MARK: - AudioFingerprinting

    nonisolated func fingerprint(for url: URL) async throws -> Fingerprint {
        // LAW-I3: Standardize before key derivation and delegation.
        let standardizedURL = url.standardizedFileURL

        // LAW-K2: Key derived from inode + volume, never from raw path string.
        let key  = try FileProcessingCacheKeyResolver.key(for: standardizedURL)
        let base = self.base

        return try await cache.result(for: key) {
            try await base.fingerprint(for: standardizedURL)
        }
    }
}
