//
//  AudioComparisonResultFormatter.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Formats `AudioComparisonResult` values into human-readable strings.
///
/// LAW-D1: Caseless enum — prevents instantiation, no static stored state.
/// LAW-N1: One primary type per file.
///
/// All methods are explicitly `nonisolated` so they can be called from any
/// concurrency context without dispatching to the main actor.
enum AudioComparisonResultFormatter {

    // MARK: - Public API

    /// Returns a multi-line summary paragraph for `result`.
    ///
    /// Example:
    /// ```
    /// Overall similarity: 78 %.
    /// Changed: 0:14–0:28, 1:03–1:17.
    /// Unchanged: 0:00–0:14, 0:28–1:03.
    /// Best partial match: 0:28–1:03 (91 % similarity).
    /// ```
    nonisolated static func summary(
        for result: AudioComparisonResult,
        decimalPlaces: Int = 0
    ) -> String {
        var lines = [String]()
        lines.reserveCapacity(4)

        lines.append(
            "Overall similarity: \(formatPercent(result.overallSimilarity, places: decimalPlaces))."
        )

        if result.changedRanges.isEmpty {
            lines.append("No changed sections detected.")
        } else {
            let ranges = result.changedRanges
                .map { formatTimeRange($0) }
                .joined(separator: ", ")
            lines.append("Changed: \(ranges).")
        }

        if result.matchedRanges.isEmpty {
            lines.append("No matching sections detected.")
        } else {
            let ranges = result.matchedRanges
                .map { formatTimeRange($0) }
                .joined(separator: ", ")
            lines.append("Unchanged: \(ranges).")
        }

        if result.hasPartialMatch, let best = result.bestPartialMatchRange {
            let pct = formatPercent(best.similarity, places: decimalPlaces)
            lines.append(
                "Best partial match: \(formatTimeRange(best)) (\(pct) similarity)."
            )
        }

        return lines.joined(separator: "\n")
    }

    /// Returns a segment-by-segment table as a multi-line string.
    ///
    /// Each row:
    /// ```
    /// Seg  3  [0:06–0:09]  ███████░░░  70 %  ← changed
    /// ```
    nonisolated static func segmentTable(
        for result: AudioComparisonResult,
        timeRanges: [SegmentTimeRange],
        barWidth: Int = 10,
        changeThreshold: Double = 0.85
    ) -> String {
        let rows: [String] = result.segmentSimilarities
            .enumerated()
            .map { idx, sim in
                let timeLabel: String
                if idx < timeRanges.count {
                    let r = timeRanges[idx]
                    timeLabel = "[\(formatTime(r.start))–\(formatTime(r.end))]"
                } else {
                    timeLabel = "[?–?]"
                }

                let bar      = progressBar(value: sim, width: barWidth)
                let pct      = formatPercent(sim, places: 0)
                let flag     = sim < changeThreshold ? "  ← changed" : ""
                let segLabel = String(format: "Seg %2d", idx)

                return "\(segLabel)  \(timeLabel)  \(bar)  \(pct)\(flag)"
            }

        return rows.joined(separator: "\n")
    }

    // MARK: - Private helpers
    // All marked `nonisolated` to prevent Swift from inferring @MainActor
    // isolation from the surrounding call context.

    private nonisolated static func formatTimeRange(_ range: AudioTimeRange) -> String {
        "\(formatTime(range.start))–\(formatTime(range.end))"
    }

    private nonisolated static func formatTime(_ t: TimeInterval) -> String {
        let total   = Int(t)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private nonisolated static func formatPercent(
        _ value: Double,
        places: Int
    ) -> String {
        String(format: "%.\(places)f %%", value * 100)
    }

    private nonisolated static func progressBar(
        value: Double,
        width: Int
    ) -> String {
        let filled = Int((value * Double(width)).rounded())
        let empty  = max(0, width - filled)
        return String(repeating: "█", count: filled)
             + String(repeating: "░", count: empty)
    }
}
