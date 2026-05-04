//
//  AVFoundationPCMHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import CryptoKit
import Foundation

/// Computes a SHA-256 hash of decoded audio PCM content using a two-task pipeline.
///
/// ## Pipeline
/// ```
/// ┌──────────────┐   AudioSampleStream   ┌───────────────┐
/// │ Decode Task  │──────────────────────►│ Hashing Task  │
/// │ (producer)   │  yield([Float])        │ (consumer)    │
/// └──────────────┘                        └───────────────┘
/// ```
///
/// Samples are quantized to `Int16` before hashing to ensure that minor
/// floating-point rounding differences in the decoding path do not produce
/// different hashes for the same audio content.
///
/// LAW-C1: struct — async work lives in a nonisolated async method.
/// LAW-H1: SHA-256 used exclusively through CryptoKit.
/// LAW-H2: `.hexString` used via `CryptoKit.Digest` extension.
struct AVFoundationPCMHasher: PCMHashing {

    // MARK: - Dependencies

    private let targetSampleRate: Double
    private let decoder: any AudioPCMDecoding

    // MARK: - Init

    init(targetSampleRate: Double, decoder: any AudioPCMDecoding) {
        self.targetSampleRate = targetSampleRate
        self.decoder          = decoder
    }

    // MARK: - PCMHashing

    nonisolated func pcmHash(for url: URL) async throws -> String {
        // LAW-C5: Check cancellation before any expensive work.
        try Task.checkCancellation()

        // LAW-I3: Standardize before use.
        let standardizedURL = url.standardizedFileURL

        // LAW-C6: Capture all dependencies as locals before entering the group.
        let targetSampleRate = self.targetSampleRate
        let decoder          = self.decoder
        let sampleStream     = AudioSampleStreamFactory.makeStream()

        return try await withThrowingTaskGroup(of: String?.self) { group in

            // ── Task 1: Decode ────────────────────────────────────────────
            group.addTask(priority: .utility) {
                // LAW-C4: First statement in every Task closure.
                try Task.checkCancellation()
                do {
                    try decoder.decodeMonoFloat32Samples(
                        from: standardizedURL,
                        sampleRate: targetSampleRate,
                        maxDuration: nil
                    ) { samples in
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

            // ── Task 2: Hash ──────────────────────────────────────────────
            group.addTask(priority: .utility) {
                // LAW-C4: First statement in every Task closure.
                try Task.checkCancellation()

                var hasher = SHA256()
                for try await samples in sampleStream.stream {
                    // LAW-C5: Check on every async iteration.
                    try Task.checkCancellation()

                    let quantized = samples.map(Self.quantize)
                    let data = quantized.withUnsafeBufferPointer { Data(buffer: $0) }
                    hasher.update(data: data)
                }

                // LAW-H2: Use .hexString extension, never inline map/joined.
                return hasher.finalize().hexString
            }

            // ── Collect ───────────────────────────────────────────────────
            while let result = try await group.next() {
                if let hash = result {
                    group.cancelAll()
                    return hash
                }
            }

            throw AudioAnalysisImplementationError.decodeFailed(
                "PCM hashing failed for '\(standardizedURL.lastPathComponent)'."
            )
        }
    }

    // MARK: - Private quantization

    /// Converts a float sample in [-1, 1] to a little-endian `Int16`.
    ///
    /// Quantization ensures hash stability across minor floating-point
    /// rounding differences in the AVFoundation decode path.
    private nonisolated static func quantize(_ sample: Float) -> Int16 {
        let clamped = max(-1, min(1, sample))
        return Int16((clamped * Float(Int16.max)).rounded()).littleEndian
    }
}
