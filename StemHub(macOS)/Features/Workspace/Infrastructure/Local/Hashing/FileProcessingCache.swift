//
//  FileProcessingCache.swift
//  StemHub(macOS)
//
// Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct FileProcessingCacheKey: Hashable, Sendable {
    let standardizedPath: String
    let fileSize: Int64
    let contentModificationTime: Int64
}

enum FileProcessingCacheKeyResolver {
    nonisolated static func key(for url: URL) throws -> FileProcessingCacheKey {
        let standardizedURL = url.standardizedFileURL
        let values = try standardizedURL.resourceValues(forKeys: [
            .fileSizeKey,
            .contentModificationDateKey
        ])

        let modificationTime = Int64(
            ((values.contentModificationDate?.timeIntervalSince1970) ?? 0) * 1_000_000
        )

        return FileProcessingCacheKey(
            standardizedPath: standardizedURL.path,
            fileSize: Int64(values.fileSize ?? 0),
            contentModificationTime: modificationTime
        )
    }
}

actor FileProcessingCacheActor<Result: Sendable> {
    private var resultsByKey: [FileProcessingCacheKey: Result] = [:]
    private var inFlightTasks: [FileProcessingCacheKey: Task<Result, Error>] = [:]

    func result(for key: FileProcessingCacheKey,
                createTask: @Sendable @escaping () -> Task<Result, Error>) async throws -> Result {
        if let cached = resultsByKey[key] {
            return cached
        }

        if let task = inFlightTasks[key] {
            return try await task.value
        }

        let task = createTask()
        inFlightTasks[key] = task

        do {
            let result = try await task.value
            resultsByKey[key] = result
            inFlightTasks[key] = nil
            return result
        } catch {
            inFlightTasks[key] = nil
            throw error
        }
    }

    func clear(for key: FileProcessingCacheKey) {
        resultsByKey[key] = nil
        inFlightTasks[key]?.cancel()
        inFlightTasks[key] = nil
    }

    func clearAll() {
        for task in inFlightTasks.values {
            task.cancel()
        }

        inFlightTasks.removeAll()
        resultsByKey.removeAll()
    }
}

