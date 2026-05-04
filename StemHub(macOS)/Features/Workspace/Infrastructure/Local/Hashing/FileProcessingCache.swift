//
//  FileProcessingCache.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation
// Cache mutation is actor-isolated; I/O runs off-actor.
actor FileProcessingCacheActor<Result: Sendable> {

    private struct InFlight: Sendable {
        let id: UInt64
        let task: Task<Result, Error>
    }

    private var resultsByKey: [String: Result] = [:]
    private var inFlightTasks: [String: InFlight] = [:]
    private var nextInFlightID: UInt64 = 0

    func result(for key: FileProcessingCacheKey,
                operation: @Sendable @escaping () async throws -> Result ) async throws -> Result {
        let storageKey = key.storageKey

        if let cached = resultsByKey[storageKey] { return cached }

        if let inFlight = inFlightTasks[storageKey] { return try await inFlight.task.value }

        let id = makeInFlightID()

        let task = Task<Result, Error>(priority: .utility) {
            try Task.checkCancellation()
            return try await operation()
        }

        inFlightTasks[storageKey] = InFlight(id: id, task: task)

        do {
            let value = try await task.value

            guard inFlightTasks[storageKey]?.id == id else { throw CancellationError() }

            resultsByKey[storageKey] = value
            inFlightTasks[storageKey] = nil
            return value

        } catch {
            if inFlightTasks[storageKey]?.id == id {
                inFlightTasks[storageKey] = nil
            }
            throw error
        }
    }

    func clear(for key: FileProcessingCacheKey) {
        let storageKey = key.storageKey
        resultsByKey[storageKey] = nil
        inFlightTasks[storageKey]?.task.cancel()
        inFlightTasks[storageKey] = nil
    }

    func clearAll() {
        for inFlight in inFlightTasks.values {
            inFlight.task.cancel()
        }
        inFlightTasks.removeAll()
        resultsByKey.removeAll()
    }


    private func makeInFlightID() -> UInt64 {
        nextInFlightID &+= 1
        return nextInFlightID
    }
}
