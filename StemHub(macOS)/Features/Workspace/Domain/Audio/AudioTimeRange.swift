//
//  AudioTimeRange.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A half-open time interval with an associated similarity score.
struct AudioTimeRange: Sendable, Equatable, Codable {
    /// Start time in seconds from the beginning of the analysed audio.
    let start: TimeInterval

    /// End time in seconds from the beginning of the analysed audio.
    let end: TimeInterval

    /// Cosine similarity score in the range [0, 1] for this interval.
    let similarity: Double
}
