//
//  CachedFileHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct CachedFileHasher: FileHashing {
    private let base: any FileHashing
    private let memoryCache: FileProcessingCacheActor<String>
    private let persistentCache: FileHashCacheStoring?
    private let maxPersistentEntries: Int
    
    init(
        base: any FileHashing,
        memoryCache: FileProcessingCacheActor<String> = FileProcessingCacheActor(),
        persistentCache: FileHashCacheStoring? = nil,
        maxPersistentEntries: Int = FileHashCacheConstants.defaultMaxEntries
    ) {
        self.base = base
        self.memoryCache = memoryCache
        self.persistentCache = persistentCache
        self.maxPersistentEntries = maxPersistentEntries
    }
    
    nonisolated func fileHash(for url: URL) async throws -> String {
        let standardizedURL = url.standardizedFileURL
        let key = try FileProcessingCacheKeyResolver.key(for: standardizedURL)
        let storageKey = key.storageKey
        
        let base = base
        let persistentCache = persistentCache
        let maxPersistentEntries = maxPersistentEntries
        
        return try await memoryCache.result(for: key) {
            if let cached = try await persistentCache?.cachedHash(for: storageKey, algorithmVersion: FileHashCacheConstants.algorithmVersion) { return cached }
            
            let hash = try await base.fileHash(for: standardizedURL)
            
            try await persistentCache?.saveHash(hash, for: storageKey, algorithmVersion: FileHashCacheConstants.algorithmVersion)
            
            try await persistentCache?.evictIfNeeded(
                maxEntries: maxPersistentEntries
            )
            
            return hash
        }
    }
}
