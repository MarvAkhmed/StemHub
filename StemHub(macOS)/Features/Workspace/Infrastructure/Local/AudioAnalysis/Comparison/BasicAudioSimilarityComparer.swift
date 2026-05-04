//
//  BasicAudioSimilarityComparer.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Computes cosine similarity between two `BasicAudioFingerprint` feature vectors.
///
/// LAW-C1: struct — similarity computation is stateless and deterministic.
struct BasicAudioSimilarityComparer: AudioSimilarityComparing {
    typealias Fingerprint = BasicAudioFingerprint

    // MARK: - AudioSimilarityComparing
    nonisolated func similarity(between lhs: BasicAudioFingerprint, and rhs: BasicAudioFingerprint) throws -> Double {
        guard !lhs.featureVector.isEmpty, !rhs.featureVector.isEmpty else {
            return 0
        }

        let count = min(lhs.featureVector.count, rhs.featureVector.count)
        guard count > 0 else { return 0 }

        let lhsSlice = lhs.featureVector.prefix(count)
        let rhsSlice = rhs.featureVector.prefix(count)

        let dotProduct = zip(lhsSlice, rhsSlice).reduce(Double.zero) { acc, pair in
            acc + Double(pair.0 * pair.1)
        }
        let lhsMagnitude = sqrt(lhsSlice.reduce(Double.zero) { $0 + Double($1 * $1) })
        let rhsMagnitude = sqrt(rhsSlice.reduce(Double.zero) { $0 + Double($1 * $1) })

        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }

        return min(1, max(0, dotProduct / (lhsMagnitude * rhsMagnitude)))
    }
}
