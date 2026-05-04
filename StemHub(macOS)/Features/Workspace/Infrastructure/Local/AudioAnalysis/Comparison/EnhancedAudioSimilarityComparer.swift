//
//  EnhancedAudioSimilarityComparer.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

//  Algorithm layers
//  ─────────────────
//  1. Full-vector cosine similarity     → overallSimilarity
//  2. Per-segment cosine similarity     → segmentSimilarities[]
//  3. DTW path (O(M×N) lightweight)     → aligns segments when lengths differ
//  4. Threshold sweep                   → changedRanges / matchedRanges
//  5. Sliding-window max                → bestPartialMatchRange / hasPartialMatch

import Accelerate
import Foundation

/// Produces a full `AudioComparisonResult` by aligning and comparing
/// two `EnhancedAudioFingerprint` values using DTW + cosine similarity.
///
/// LAW-C1: struct — all operations are pure functions over immutable inputs.
struct EnhancedAudioSimilarityComparer: AudioSimilarityComparing {
    typealias Fingerprint = EnhancedAudioFingerprint

    // MARK: - Configuration

    let matchThreshold:              Double
    let partialMatchWindowFraction:  Double
    let minimumPartialMatchSegments: Int

    // MARK: - Init

    init(
        matchThreshold:              Double = 0.85,
        partialMatchWindowFraction:  Double = 0.75,
        minimumPartialMatchSegments: Int    = 4
    ) {
        self.matchThreshold              = matchThreshold
        self.partialMatchWindowFraction  = partialMatchWindowFraction
        self.minimumPartialMatchSegments = minimumPartialMatchSegments
    }

    // MARK: - AudioSimilarityComparing

    nonisolated func similarity(
        between lhs: EnhancedAudioFingerprint,
        and rhs: EnhancedAudioFingerprint
    ) throws -> Double {
        try compare(lhs: lhs, rhs: rhs).overallSimilarity
    }

    // MARK: - Full comparison

    nonisolated func compare(
        lhs: EnhancedAudioFingerprint,
        rhs: EnhancedAudioFingerprint
    ) throws -> AudioComparisonResult {
        // Validate compatibility before performing any work.
        try validateCompatibility(lhs: lhs, rhs: rhs)

        // ── 1. Whole-file cosine similarity ──────────────────────────────
        let overall = cosineSimilarity(
            lhs: lhs.featureVector,
            rhs: rhs.featureVector
        )

        // ── 2. DTW segment alignment ──────────────────────────────────────
        let alignedPairs = dtwAlign(
            lhsSegments: lhs.segmentFeatures,
            rhsSegments: rhs.segmentFeatures
        )

        // ── 3. Per-segment cosine similarity ─────────────────────────────
        var segmentScores = [Double](repeating: 0, count: lhs.segmentFeatures.count)
        var segmentCounts = [Int](repeating: 0,    count: lhs.segmentFeatures.count)

        for (lhsIdx, rhsIdx) in alignedPairs {
            let score = cosineSimilarity(
                lhs: lhs.segmentFeatures[lhsIdx],
                rhs: rhs.segmentFeatures[rhsIdx]
            )
            segmentScores[lhsIdx] += score
            segmentCounts[lhsIdx] += 1
        }

        let segmentSimilarities: [Double] = segmentScores
            .enumerated()
            .map { idx, sum in
                let count = segmentCounts[idx]
                return count > 0 ? sum / Double(count) : 0
            }

        // ── 4. Changed / matched time ranges ─────────────────────────────
        let (changedRanges, matchedRanges) = buildTimeRanges(
            segmentSimilarities: segmentSimilarities,
            timeRanges:          lhs.segmentTimeRanges,
            threshold:           matchThreshold
        )

        // ── 5. Partial match detection ────────────────────────────────────
        let windowSize = max(
            minimumPartialMatchSegments,
            Int(Double(lhs.segmentFeatures.count) * partialMatchWindowFraction)
        )
        let (hasPartialMatch, bestWindow) = detectPartialMatch(
            segmentSimilarities: segmentSimilarities,
            timeRanges:          lhs.segmentTimeRanges,
            windowSize:          windowSize,
            threshold:           matchThreshold
        )

        return AudioComparisonResult(
            overallSimilarity:     overall,
            segmentSimilarities:   segmentSimilarities,
            changedRanges:         changedRanges,
            matchedRanges:         matchedRanges,
            hasPartialMatch:       hasPartialMatch,
            bestPartialMatchRange: bestWindow
        )
    }
}

// MARK: - DTW alignment

private extension EnhancedAudioSimilarityComparer {

    /// O(M×N) DTW returning an alignment path as `[(lhsIndex, rhsIndex)]` pairs
    /// in chronological order.
    ///
    /// Uses cosine distance (1 − similarity) as the local cost.
    /// The path maps every LHS segment to exactly one RHS segment; multiple
    /// RHS segments can map onto a single LHS segment (many-to-one).
    nonisolated func dtwAlign(
        lhsSegments: [[Float]],
        rhsSegments: [[Float]]
    ) -> [(lhsIdx: Int, rhsIdx: Int)] {
        let m = lhsSegments.count
        let n = rhsSegments.count
        guard m > 0, n > 0 else { return [] }

        // ── Build cost matrix (row-major: cost[i * n + j]) ───────────────
        var cost = [Double](repeating: .infinity, count: m * n)

        func cellIndex(_ i: Int, _ j: Int) -> Int { i * n + j }

        for i in 0..<m {
            for j in 0..<n {
                let localCost = 1.0 - cosineSimilarity(
                    lhs: lhsSegments[i],
                    rhs: rhsSegments[j]
                )

                // Determine the minimum predecessor cost.
                // Only (0, 0) has a zero predecessor; all border cells that
                // have only one valid predecessor use that predecessor's cost;
                // all other cells take the minimum of the three neighbours.
                let predecessor: Double
                switch (i, j) {
                case (0, 0):
                    predecessor = 0
                case (0, _):
                    // Top row — can only come from the left.
                    predecessor = cost[cellIndex(0, j - 1)]
                case (_, 0):
                    // Left column — can only come from above.
                    predecessor = cost[cellIndex(i - 1, 0)]
                default:
                    let diag = cost[cellIndex(i - 1, j - 1)]
                    let up   = cost[cellIndex(i - 1, j)]
                    let left = cost[cellIndex(i, j - 1)]
                    predecessor = Swift.min(diag, Swift.min(up, left))
                }

                cost[cellIndex(i, j)] = localCost + predecessor
            }
        }

        // ── Backtrace from (m-1, n-1) to (0, 0) ─────────────────────────
        var path: [(lhsIdx: Int, rhsIdx: Int)] = []
        path.reserveCapacity(m + n)

        var i = m - 1
        var j = n - 1

        while i > 0 || j > 0 {
            path.append((i, j))
            switch (i, j) {
            case (0, _):
                // Reached top row — can only move left.
                j -= 1
            case (_, 0):
                // Reached left column — can only move up.
                i -= 1
            default:
                let diagCost = cost[cellIndex(i - 1, j - 1)]
                let upCost   = cost[cellIndex(i - 1, j)]
                let leftCost = cost[cellIndex(i, j - 1)]

                if diagCost <= upCost, diagCost <= leftCost {
                    i -= 1; j -= 1
                } else if upCost <= leftCost {
                    i -= 1
                } else {
                    j -= 1
                }
            }
        }

        // Always include the origin cell.
        path.append((0, 0))

        // Return path in forward chronological order.
        return path.reversed()
    }
}

// MARK: - Time-range builders

private extension EnhancedAudioSimilarityComparer {

    /// Groups contiguous segments into `AudioTimeRange` values based on whether
    /// each segment's similarity meets `threshold`.
    ///
    /// - Parameters:
    ///   - segmentSimilarities: Per-segment similarity scores in [0, 1].
    ///   - timeRanges: Per-segment time spans from the fingerprint.
    ///   - threshold: The minimum score to classify a segment as "matched".
    /// - Returns: A tuple of `(changed: [AudioTimeRange], matched: [AudioTimeRange])`.
    nonisolated func buildTimeRanges(
        segmentSimilarities: [Double],
        timeRanges:          [SegmentTimeRange],
        threshold:           Double
    ) -> (changed: [AudioTimeRange], matched: [AudioTimeRange]) {
        guard !segmentSimilarities.isEmpty else { return ([], []) }

        var changed = [AudioTimeRange]()
        var matched = [AudioTimeRange]()

        // Run-length encoding state.
        var runStart     = 0
        var runIsMatched = segmentSimilarities[0] >= threshold
        var runSimSum    = segmentSimilarities[0]

        /// Closes the current run and appends an `AudioTimeRange` to the
        /// appropriate output array.
        ///
        /// - Parameters:
        ///   - endExclusive: The index one past the last segment in the run.
        ///   - start: The first segment index of the run.
        ///   - isMatched: `true` if the run is matched, `false` if changed.
        ///   - simSum: The sum of similarity scores across the run.
        func flushRun(
            endExclusive: Int,
            start:        Int,
            isMatched:    Bool,
            simSum:       Double
        ) {
            guard
                endExclusive > start,
                start < timeRanges.count,
                endExclusive - 1 < timeRanges.count
            else { return }

            let range = AudioTimeRange(
                start:      timeRanges[start].start,
                end:        timeRanges[endExclusive - 1].end,
                similarity: simSum / Double(endExclusive - start)
            )

            if isMatched {
                matched.append(range)
            } else {
                changed.append(range)
            }
        }

        for idx in 1..<segmentSimilarities.count {
            let isMatched = segmentSimilarities[idx] >= threshold

            if isMatched != runIsMatched {
                flushRun(
                    endExclusive: idx,
                    start:        runStart,
                    isMatched:    runIsMatched,
                    simSum:       runSimSum
                )
                runStart     = idx
                runIsMatched = isMatched
                runSimSum    = segmentSimilarities[idx]
            } else {
                runSimSum += segmentSimilarities[idx]
            }
        }

        // Flush the final run.
        flushRun(
            endExclusive: segmentSimilarities.count,
            start:        runStart,
            isMatched:    runIsMatched,
            simSum:       runSimSum
        )

        return (changed, matched)
    }

    /// Finds the sliding window of `windowSize` segments with the highest
    /// average similarity and reports it as a partial match if the average
    /// meets `threshold`.
    ///
    /// - Parameters:
    ///   - segmentSimilarities: Per-segment similarity scores.
    ///   - timeRanges: Per-segment time spans from the fingerprint.
    ///   - windowSize: The number of consecutive segments to include per window.
    ///   - threshold: The minimum average score to declare a partial match.
    /// - Returns: A tuple of `(hasMatch: Bool, bestRange: AudioTimeRange?)`.
    nonisolated func detectPartialMatch(
        segmentSimilarities: [Double],
        timeRanges:          [SegmentTimeRange],
        windowSize:          Int,
        threshold:           Double
    ) -> (hasMatch: Bool, bestRange: AudioTimeRange?) {
        let count = segmentSimilarities.count
        guard windowSize > 0, count >= windowSize else { return (false, nil) }

        // Seed with the first window.
        var windowSum = segmentSimilarities.prefix(windowSize).reduce(0, +)
        var bestSum   = windowSum
        var bestStart = 0

        // Slide the window only when there are more positions to check.
        if count > windowSize {
            for start in 1...(count - windowSize) {
                windowSum -= segmentSimilarities[start - 1]
                windowSum += segmentSimilarities[start + windowSize - 1]
                if windowSum > bestSum {
                    bestSum   = windowSum
                    bestStart = start
                }
            }
        }

        let bestAvg  = bestSum / Double(windowSize)
        let hasMatch = bestAvg >= threshold

        guard
            hasMatch,
            bestStart < timeRanges.count,
            (bestStart + windowSize - 1) < timeRanges.count
        else {
            return (false, nil)
        }

        let bestRange = AudioTimeRange(
            start:      timeRanges[bestStart].start,
            end:        timeRanges[bestStart + windowSize - 1].end,
            similarity: bestAvg
        )

        return (true, bestRange)
    }
}

// MARK: - Cosine similarity

private extension EnhancedAudioSimilarityComparer {

    /// Computes the cosine similarity between two equal-length `[Float]` vectors.
    ///
    /// Uses vDSP for hardware-accelerated dot-product and sum-of-squares.
    /// Returns 0 for zero-magnitude vectors or mismatched lengths.
    ///
    /// - Parameters:
    ///   - lhs: The first feature vector.
    ///   - rhs: The second feature vector (must have the same count as `lhs`).
    /// - Returns: A value in [0, 1].
    nonisolated func cosineSimilarity(lhs: [Float], rhs: [Float]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }

        let count = vDSP_Length(lhs.count)
        var dot      = Float.zero
        var lhsSumSq = Float.zero
        var rhsSumSq = Float.zero

        vDSP_dotpr(lhs, 1, rhs, 1, &dot,      count)
        vDSP_svesq(lhs, 1,         &lhsSumSq, count)
        vDSP_svesq(rhs, 1,         &rhsSumSq, count)

        let denom = sqrt(Double(lhsSumSq)) * sqrt(Double(rhsSumSq))
        guard denom > 0 else { return 0 }

        return min(1, max(0, Double(dot) / denom))
    }
}

// MARK: - Compatibility validation

private extension EnhancedAudioSimilarityComparer {

    /// Validates that `lhs` and `rhs` are structurally compatible for comparison.
    ///
    /// Throws `AudioAnalysisImplementationError.invalidFingerprint` with a
    /// descriptive message for every detected incompatibility.
    nonisolated func validateCompatibility(
        lhs: EnhancedAudioFingerprint,
        rhs: EnhancedAudioFingerprint
    ) throws {
        try assertEqual(
            lhs.metadata.featureLayoutVersion,
            rhs.metadata.featureLayoutVersion,
            field: "featureLayoutVersion"
        )
        try assertEqual(
            lhs.metadata.frameSize,
            rhs.metadata.frameSize,
            field: "frameSize"
        )
        try assertEqual(
            lhs.metadata.hopSize,
            rhs.metadata.hopSize,
            field: "hopSize"
        )
        try assertEqual(
            lhs.metadata.featuresPerSegment,
            rhs.metadata.featuresPerSegment,
            field: "featuresPerSegment"
        )
        try assertEqual(
            lhs.featureVector.count,
            rhs.featureVector.count,
            field: "featureVector.count"
        )

        // Validate that each fingerprint's segment arrays are internally consistent.
        try assertEqual(
            lhs.segmentFeatures.count,
            lhs.segmentTimeRanges.count,
            field: "LHS segmentFeatures.count vs segmentTimeRanges.count"
        )
        try assertEqual(
            rhs.segmentFeatures.count,
            rhs.segmentTimeRanges.count,
            field: "RHS segmentFeatures.count vs segmentTimeRanges.count"
        )

        // Validate per-segment feature dimensions.
        try validateSegmentDimensions(
            lhs.segmentFeatures,
            expectedCount: lhs.metadata.featuresPerSegment,
            side: "LHS"
        )
        try validateSegmentDimensions(
            rhs.segmentFeatures,
            expectedCount: rhs.metadata.featuresPerSegment,
            side: "RHS"
        )
    }

    /// Throws if `lhsValue != rhsValue`, with a message naming the `field`.
    private nonisolated func assertEqual<T: Equatable>(
        _ lhsValue: T,
        _ rhsValue: T,
        field: String
    ) throws {
        guard lhsValue == rhsValue else {
            throw AudioAnalysisImplementationError.invalidFingerprint(
                """
                Cannot compare enhanced fingerprints: '\(field)' mismatch. \
                LHS: \(lhsValue), RHS: \(rhsValue).
                """
            )
        }
    }

    /// Validates that every segment vector has exactly `expectedCount` features.
    private nonisolated func validateSegmentDimensions(
        _ segments:      [[Float]],
        expectedCount:   Int,
        side:            String
    ) throws {
        for (index, segment) in segments.enumerated() {
            guard segment.count == expectedCount else {
                throw AudioAnalysisImplementationError.invalidFingerprint(
                    """
                    \(side) segment \(index) has invalid feature count. \
                    Expected \(expectedCount), got \(segment.count).
                    """
                )
            }
        }
    }
}
