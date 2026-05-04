//
//  CachedPCMHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Decorates any `PCMHashing` implementation with file-level caching.
///
/// LAW-K1: Pure decorator — zero domain logic.
/// LAW-K2: Cache key derived from inode + volume via `FileProcessingCacheKeyResolver`.
/// LAW-D2: `cache` must be injected; `CachedPCMHasher` is not a leaf type.
struct CachedPCMHasher: PCMHashing {

    // MARK: - Dependencies

    private let base:  any PCMHashing
    private let cache: FileProcessingCacheActor<String>

    // MARK: - Init

    /// - Parameters:
    ///   - base: The underlying hasher to delegate cache misses to.
    ///   - cache: The shared cache actor. Must be injected; never default-constructed.
    init(base: any PCMHashing, cache: FileProcessingCacheActor<String>) {
        self.base  = base
        self.cache = cache
    }

    // MARK: - PCMHashing

    nonisolated func pcmHash(for url: URL) async throws -> String {
        // LAW-I3: Standardize before key derivation and delegation.
        let standardizedURL = url.standardizedFileURL

        // LAW-K2: Inode + volume key, never raw path string.
        let key  = try FileProcessingCacheKeyResolver.key(for: standardizedURL)
        let base = self.base

        return try await cache.result(for: key) {
            try await base.pcmHash(for: standardizedURL)
        }
    }
}
