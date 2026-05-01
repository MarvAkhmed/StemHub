//
//  AnalysisLimiterActor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

actor AnalysisLimiterActor {
    private let maxConcurrent: Int
    private var running = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrent: Int) {
        self.maxConcurrent = max(1, maxConcurrent)
    }

    func acquire() async {
        if running < maxConcurrent {
            running += 1
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        if let continuation = waiters.first {
            waiters.removeFirst()
            continuation.resume()
        } else {
            running = max(0, running - 1)
        }
    }

    func withSlot<Result: Sendable>(
        _ operation: @Sendable () async throws -> Result
    ) async throws -> Result {
        await acquire()
        defer { release() }
        return try await operation()
    }
}
