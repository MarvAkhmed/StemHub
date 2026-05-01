//
//  CachedPCMHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct CachedPCMHasher: PCMHashing {
    private let base: any PCMHashing
    private let cache: FileProcessingCacheActor<String>

    init(
        base: any PCMHashing,
        cache: FileProcessingCacheActor<String> = FileProcessingCacheActor()
    ) {
        self.base = base
        self.cache = cache
    }

    nonisolated func pcmHash(for url: URL) async throws -> String {
        let standardizedURL = url.standardizedFileURL
        let key = try FileProcessingCacheKeyResolver.key(for: standardizedURL)
        let base = base

        return try await cache.result(for: key) {
            Task {
                try await base.pcmHash(for: standardizedURL)
            }
        }
    }
}

