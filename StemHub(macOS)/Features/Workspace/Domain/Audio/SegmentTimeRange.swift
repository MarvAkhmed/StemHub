//
//  SegmentTimeRange.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// The time span of a single analysis segment within the trimmed audio.
struct SegmentTimeRange: Sendable, Equatable, Codable {
    /// Start time in seconds from the trimmed audio start.
    let start: TimeInterval
    /// End time in seconds from the trimmed audio start.
    let end: TimeInterval
}
