//
//  CachedFileHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

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
            Task {
                try await base.fileHash(for: standardizedURL)
            }
        }
    }
}

