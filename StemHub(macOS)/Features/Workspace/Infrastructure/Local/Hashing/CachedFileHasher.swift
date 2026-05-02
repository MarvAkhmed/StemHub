//
//  CachedFileHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

// ── Cached wrapper ────────────────────────────────────────────────────────────
//
// A Sendable value type that wraps any FileHashing and transparently caches
// results in FileProcessingCacheActor<String>.
//
// All stored properties are either Sendable protocol existentials or actors,
// so the struct itself is Sendable without @unchecked.

struct CachedFileHasher: FileHashing {
    private let base: any FileHashing
    private let cache: FileProcessingCacheActor<String>

    init(
        base: any FileHashing,
        cache: FileProcessingCacheActor<String> = FileProcessingCacheActor()
    ) {
        self.base = base
        self.cache = cache
    }

    nonisolated func fileHash(for url: URL) async throws -> String {
        let standardizedURL = url.standardizedFileURL
        let key = try FileProcessingCacheKeyResolver.key(for: standardizedURL)
        let base = base
        return try await cache.result(for: key) {
            try await base.fileHash(for: standardizedURL)
        }
    }
}
