//
//  BasicAudioSimilarityComparer.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 01.05.2026.
//

import Foundation

protocol AudioSimilarityComparing: Sendable {
    associatedtype Fingerprint: Sendable
    nonisolated func similarity(between lhs: Fingerprint, and rhs: Fingerprint) throws -> Double
}

struct BasicAudioSimilarityComparer: AudioSimilarityComparing {
    typealias Fingerprint = BasicAudioFingerprint

    nonisolated func similarity(
        between lhs: BasicAudioFingerprint,
        and rhs: BasicAudioFingerprint
    ) throws -> Double {
        guard !lhs.featureVector.isEmpty, !rhs.featureVector.isEmpty else {
            return 0
        }

        let count = min(lhs.featureVector.count, rhs.featureVector.count)
        guard count > 0 else {
            return 0
        }

        let lhsSlice = lhs.featureVector.prefix(count)
        let rhsSlice = rhs.featureVector.prefix(count)

        let dotProduct = zip(lhsSlice, rhsSlice).reduce(Double.zero) { partialResult, pair in
            partialResult + Double(pair.0 * pair.1)
        }

        let lhsMagnitude = sqrt(
            lhsSlice.reduce(Double.zero) { partialResult, value in
                partialResult + Double(value * value)
            }
        )
        let rhsMagnitude = sqrt(
            rhsSlice.reduce(Double.zero) { partialResult, value in
                partialResult + Double(value * value)
            }
        )

        guard lhsMagnitude > 0, rhsMagnitude > 0 else {
            return 0
        }

        let cosineSimilarity = dotProduct / (lhsMagnitude * rhsMagnitude)
        return min(1, max(0, cosineSimilarity))
    }
}
