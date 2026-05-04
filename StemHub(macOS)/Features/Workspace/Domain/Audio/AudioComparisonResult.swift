//
//  AudioComparisonResult.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// The output of a full audio comparison between two fingerprints.
struct AudioComparisonResult: Sendable, Equatable, Codable {
    /// Whole-file cosine similarity in the range [0, 1].
    let overallSimilarity: Double

    /// Per-aligned-segment cosine similarity values.
    let segmentSimilarities: [Double]

    /// Time ranges where similarity fell below the configured threshold.
    let changedRanges: [AudioTimeRange]

    /// Time ranges where similarity met or exceeded the configured threshold.
    let matchedRanges: [AudioTimeRange]

    /// `true` when a contiguous window of segments scores above the threshold.
    let hasPartialMatch: Bool

    /// The highest-scoring contiguous window, or `nil` if none was found.
    let bestPartialMatchRange: AudioTimeRange?
}
