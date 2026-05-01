//
//  AudioAnalysisCacheActor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

actor AudioAnalysisCacheActor<Result: Sendable> {
    private var resultsByFileHash: [String: Result] = [:]
    private var inFlightTasks: [String: Task<Result, Error>] = [:]

    func result(
        for fileHash: String,
        createTask: @Sendable @escaping () -> Task<Result, Error>
    ) async throws -> Result {
        if let cached = resultsByFileHash[fileHash] {
            return cached
        }

        if let task = inFlightTasks[fileHash] {
            return try await task.value
        }

        let task = createTask()
        inFlightTasks[fileHash] = task

        do {
            let result = try await task.value
            resultsByFileHash[fileHash] = result
            inFlightTasks[fileHash] = nil
            return result
        } catch {
            inFlightTasks[fileHash] = nil
            throw error
        }
    }

    func clear(fileHash: String) {
        resultsByFileHash[fileHash] = nil
        inFlightTasks[fileHash]?.cancel()
        inFlightTasks[fileHash] = nil
    }
}
