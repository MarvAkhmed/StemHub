//
//  AudioFingerprinting.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A type that can produce a fingerprint value for a given audio file URL.
///
/// - Note: `Sendable` because implementations cross concurrency boundaries
///   inside `TaskGroup` fingerprinting pipelines.
protocol AudioFingerprinting: Sendable {
    associatedtype Fingerprint: Sendable

    /// Computes and returns the fingerprint for the audio file at `url`.
    ///
    /// - Parameter url: The URL of the audio file. The implementation is
    ///   responsible for calling `.standardizedFileURL` before use.
    /// - Returns: The computed fingerprint.
    /// - Throws: `AudioAnalysisImplementationError` on decode or analysis failure.
    nonisolated func fingerprint(for url: URL) async throws -> Fingerprint
}
