//
//  FileHashCacheStoring.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 04.05.2026.
//

import Foundation
import CoreData

protocol FileHashCacheStoring: Sendable {
    func cachedHash(for key: String, algorithmVersion: String) async throws -> String?
    func saveHash(_ hash: String, for key: String, algorithmVersion: String) async throws
    func evictIfNeeded(maxEntries: Int) async throws
}


final class CoreDataFileHashCacheStore: FileHashCacheStoring, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func cachedHash(for key: String,algorithmVersion: String) async throws -> String? {
        try await container.performBackgroundTaskResult { context in
            let request = FileHashCacheEntry.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(
                format: "%K == %@",
                FileHashCacheKey.cacheKey,
                key
            )

            guard let entry = try context.fetch(request).first else { return nil }

            guard entry.algorithmVersion == algorithmVersion else {
                context.delete(entry)
                try context.saveIfNeeded()
                return nil
            }

            entry.lastAccessedAt = Date()
            try context.saveIfNeeded()

            return entry.fileHash
        }
    }

    func saveHash(_ hash: String, for key: String, algorithmVersion: String) async throws {
        try await container.performBackgroundTaskResult { context in
            let request = FileHashCacheEntry.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(
                format: "%K == %@",
                FileHashCacheKey.cacheKey,
                key
            )

            let now = Date()
            let entry = try context.fetch(request).first ?? FileHashCacheEntry(context: context)

            entry.cacheKey = key
            entry.fileHash = hash
            entry.algorithmVersion = algorithmVersion
            entry.lastAccessedAt = now

            if entry.createdAt == nil {
                entry.createdAt = now
            }

            try context.saveIfNeeded()
        }
    }

    func evictIfNeeded(maxEntries: Int) async throws {
        try await container.performBackgroundTaskResult { context in
            let countRequest = FileHashCacheEntry.fetchRequest()
            let count = try context.count(for: countRequest)

            let overflow = count - maxEntries
            guard overflow > 0 else { return }

            let request = FileHashCacheEntry.fetchRequest()
            request.fetchLimit = overflow
            request.sortDescriptors = [
                NSSortDescriptor(
                    key: FileHashCacheKey.lastAccessedAt,
                    ascending: true
                )
            ]

            let entriesToDelete = try context.fetch(request)
            entriesToDelete.forEach(context.delete)

            try context.saveIfNeeded()
        }
    }
}
