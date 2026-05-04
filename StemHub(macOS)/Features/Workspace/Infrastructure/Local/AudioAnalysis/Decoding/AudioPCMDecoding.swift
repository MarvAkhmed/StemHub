//
//  AudioPCMDecoding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Decodes an audio file at a URL into a stream of mono Float32 sample chunks.
///
/// Renamed from `AudioPCMDecoding` — name retained because it already has
/// the correct domain noun structure. Protocol marked `Sendable` per LAW-C3.
protocol AudioPCMDecoding: Sendable {
    /// Decodes the audio file at `url` and calls `processChunk` for each
    /// decoded block of samples.
    ///
    /// - Parameters:
    ///   - url: The file URL to decode (caller must pass `.standardizedFileURL`).
    ///   - sampleRate: The target output sample rate in Hz.
    ///   - maxDuration: Optional maximum duration to decode. Pass `nil` to
    ///     decode the entire file.
    ///   - processChunk: Called synchronously for each decoded chunk of samples.
    ///     May throw to abort the decode early.
    /// - Throws: `AudioAnalysisImplementationError` on any decode failure.
    nonisolated func decodeMonoFloat32Samples(from url: URL, sampleRate: Double,
                                              maxDuration: TimeInterval?, processChunk: ([Float]) throws -> Void) throws
}
