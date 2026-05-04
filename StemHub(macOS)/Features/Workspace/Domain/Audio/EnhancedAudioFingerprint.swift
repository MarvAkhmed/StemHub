//
//  EnhancedAudioFingerprint.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A rich audio fingerprint produced by the enhanced fingerprinting pipeline.
struct EnhancedAudioFingerprint: Sendable, Equatable, Codable {
    /// The version of the feature-vector layout; used to reject incompatible comparisons.
    static let featureLayoutVersion: Int = 1

    let metadata: FingerprintMetadata
    let segmentFeatures: [[Float]]
    let featureVector: [Float]
    let segmentTimeRanges: [SegmentTimeRange]
}
