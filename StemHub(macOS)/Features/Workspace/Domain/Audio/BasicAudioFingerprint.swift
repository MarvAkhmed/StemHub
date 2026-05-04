//
//  BasicAudioFingerprint.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A compact audio fingerprint produced by the basic fingerprinting pipeline.
struct BasicAudioFingerprint: Sendable, Equatable {
    let segmentCount: Int
    let featuresPerSegment: Int
    let featureVector: [Float]
}
