//
//  FingerprintMetadata.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Analysis parameters recorded alongside a fingerprint for compatibility checks.
struct FingerprintMetadata: Sendable, Equatable, Codable {
    let sampleRate: Double
    let frameSize: Int
    let hopSize: Int
    let segmentCount: Int
    let featuresPerSegment: Int
    let analyzedFrameCount: Int
    let analysisDuration: TimeInterval
    let featureLayoutVersion: Int
}
