//
//  AudioFeatureExtractorBuilding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Creates feature extractor instances configured for a given fingerprint setup.
///
/// Renamed from `AudioFeatureExtractorMaking` → `AudioFeatureExtractorBuilding`
/// (LAW-D3: approved `Building` suffix).
/// LAW-C3: Marked `Sendable`.
protocol AudioFeatureExtractorBuilding: Sendable {
    associatedtype Extractor: AudioFeatureProcessing

    /// Returns a fresh extractor configured with `configuration`.
    ///
    /// - Parameter configuration: Fingerprint analysis parameters.
    /// - Returns: A ready-to-use `Extractor` instance.
    nonisolated func extractor(configuration: AudioFingerprintConfiguration) -> Extractor
}
