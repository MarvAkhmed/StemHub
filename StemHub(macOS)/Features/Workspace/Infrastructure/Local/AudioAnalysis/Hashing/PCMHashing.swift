//
//  PCMHashing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Computes a SHA-256 hash of an audio file's decoded mono float32 PCM content.
///
/// The hash captures the audio signal, not the file container. Two files with
/// different encodings but identical waveforms will produce the same hash.
///
/// LAW-D3: `Hashing` suffix — approved.
/// LAW-C3: Marked `Sendable`.
protocol PCMHashing: Sendable {
    /// Returns the SHA-256 hex digest of the decoded PCM content at `url`.
    ///
    /// - Parameter url: The audio file URL. The implementation is responsible
    ///   for calling `.standardizedFileURL` before use.
    /// - Returns: A lowercase hex string SHA-256 digest.
    /// - Throws: `AudioAnalysisImplementationError` on decode or hashing failure.
    nonisolated func pcmHash(for url: URL) async throws -> String
}
