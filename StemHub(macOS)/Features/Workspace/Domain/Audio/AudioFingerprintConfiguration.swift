//
//  AudioFingerprintConfiguration.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Immutable configuration for audio fingerprint extraction.
///
/// - Note: All properties are value types; this struct is `Sendable` without
///   annotation because all stored properties are `Sendable`.
struct AudioFingerprintConfiguration: Sendable, Equatable {
    let targetSampleRate: Double
    let maxDuration: TimeInterval
    let frameSize: Int
    let hopSize: Int
    let segmentCount: Int

    /// Returns a configuration suitable for fast, low-resolution fingerprinting.
    ///
    /// - Note: Implemented as a static factory *function* (not a stored property)
    ///   so that each call returns a fresh value and no static state is retained.
    static func makeBasic() -> AudioFingerprintConfiguration {
        AudioFingerprintConfiguration(
            targetSampleRate: 11_025,
            maxDuration: 180,
            frameSize: 2_048,
            hopSize: 1_024,
            segmentCount: 32
        )
    }
}
