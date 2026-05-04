//
//  BasicAudioFingerprinter.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Produces `BasicAudioFingerprint` values using a two-task pipeline:
///
/// ```
/// ┌─────────────┐   AudioSampleStream   ┌──────────────────────┐
/// │ Decode Task │──────────────────────►│ Fingerprinting Task  │
/// │ (producer)  │  yield([Float])        │ (consumer)           │
/// └─────────────┘                        └──────────────────────┘
/// ```
///
/// ## Why two tasks?
/// Decoding is I/O-bound (disk reads via AVFoundation); fingerprinting is
/// CPU-bound (feature accumulation). Running them concurrently on separate
/// cooperative threads improves throughput on multi-core hardware.
///
/// ## Thread safety
/// - Both tasks capture only immutable `let` bindings or `Sendable` values.
/// - The `BasicFeatureExtractor` is a value type mutated exclusively inside
///   the fingerprinting task — no sharing, no locking required.
/// - `AudioSampleStream.continuation` is `Sendable`; it is captured by the
///   decode task and never accessed by the fingerprinting task.
/// - `AudioSampleStream.stream` is `Sendable`; it is consumed only by the
///   fingerprinting task.
///
/// LAW-C1: struct — async work lives in a nonisolated async method on a struct.
/// LAW-D2: No default parameters — this type receives all dependencies via init.
struct BasicAudioFingerprinter: AudioFingerprinting {
    typealias Fingerprint = BasicAudioFingerprint

    // MARK: - Dependencies

    private let configuration:         AudioFingerprintConfiguration
    private let decoder:               any AudioPCMDecoding
    private let featureExtractorFactory: any AudioFeatureExtractorBuilding

    // MARK: - Init

    init(
        configuration: AudioFingerprintConfiguration,
        decoder: any AudioPCMDecoding,
        featureExtractorFactory: any AudioFeatureExtractorBuilding
    ) {
        self.configuration          = configuration
        self.decoder                = decoder
        self.featureExtractorFactory = featureExtractorFactory
    }

    // MARK: - AudioFingerprinting

    nonisolated func fingerprint(for url: URL) async throws -> BasicAudioFingerprint {
        // LAW-C5: Check cancellation before any expensive work.
        try Task.checkCancellation()

        // LAW-I3: Standardize before use.
        let standardizedURL = url.standardizedFileURL

        // Capture all dependencies as local lets before entering the task group.
        // LAW-C6: Eliminates implicit self capture under -strict-concurrency=complete.
        let configuration          = self.configuration
        let decoder                = self.decoder
        let featureExtractorFactory = self.featureExtractorFactory

        // Create one stream per fingerprint call — never reuse streams.
        let sampleStream = AudioSampleStreamFactory.makeStream()

        return try await withThrowingTaskGroup(
            of: BasicAudioFingerprint?.self
        ) { group in

            // ── Task 1: Decode ────────────────────────────────────────────
            group.addTask(priority: .utility) {
                // LAW-C4: First statement in every Task closure.
                try Task.checkCancellation()
                do {
                    try decoder.decodeMonoFloat32Samples(
                        from: standardizedURL,
                        sampleRate: configuration.targetSampleRate,
                        maxDuration: configuration.maxDuration
                    ) { samples in
                        // Propagate cancellation into the synchronous decode loop.
                        try Task.checkCancellation()
                        sampleStream.continuation.yield(samples)
                    }
                    sampleStream.continuation.finish()
                } catch {
                    sampleStream.continuation.finish(throwing: error)
                    throw error
                }
                return nil
            }

            // ── Task 2: Fingerprint ───────────────────────────────────────
            group.addTask(priority: .utility) {
                // LAW-C4: First statement in every Task closure.
                try Task.checkCancellation()

                // `extractor` is a value type (struct) mutated exclusively
                // inside this task. No concurrent access is possible.
                var extractor = featureExtractorFactory.extractor(
                    configuration: configuration
                )

                for try await samples in sampleStream.stream {
                    // LAW-C5: Check on every iteration of the async for loop.
                    try Task.checkCancellation()

                    // consume and makeFingerprint are synchronous mutating
                    // methods — no `await` is used here (Bug fix from original).
                    await extractor.consume(samples)
                }

                // makeFingerprint is also synchronous — no `await`.
                return try await  extractor.makeFingerprint(
                    fileName: standardizedURL.lastPathComponent
                )
            }

            // ── Collect results ───────────────────────────────────────────
            // The decode task always returns `nil`; the fingerprint task
            // returns the result. We collect whichever non-nil result arrives.
            while let result = try await group.next() {
                if let fingerprint = result {
                    group.cancelAll()
                    return fingerprint
                }
            }

            throw AudioAnalysisImplementationError.invalidFingerprint(
                "Failed to build an audio fingerprint for '\(standardizedURL.lastPathComponent)'."
            )
        }
    }
}
