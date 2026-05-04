//
//  AudioSimilarityComparing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A type that computes a similarity score between two fingerprints.
///
/// - Note: `Sendable` so implementations can be stored in actors and
///   called from nonisolated async contexts.
protocol AudioSimilarityComparing: Sendable {
    associatedtype Fingerprint: Sendable

    /// Returns a similarity score in the range [0, 1].
    ///
    /// - Parameters:
    ///   - lhs: The first fingerprint.
    ///   - rhs: The second fingerprint.
    /// - Returns: A value in [0, 1] where 1 means identical.
    /// - Throws: `AudioAnalysisImplementationError` when the fingerprints
    ///   are incompatible.
    nonisolated func similarity(between lhs: Fingerprint, and rhs: Fingerprint) throws -> Double
}
