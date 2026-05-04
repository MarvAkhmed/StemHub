//
//  BasicAudioFeatureExtractorFactory.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Factory that produces `BasicFeatureExtractor` instances.
///
/// Conforms to `AudioFeatureExtractorBuilding`. Both the factory and the
/// extractor are value types with no further injectable dependencies,
/// making this a leaf type under LAW-D2.
///
/// ## Isolation
/// The `extractor(configuration:)` method is `nonisolated` per the protocol
/// requirement. `BasicFeatureExtractor.init` is also `nonisolated` (no actor
/// annotation on the struct), so the call is valid from any context.
struct BasicAudioFeatureExtractorFactory: AudioFeatureExtractorBuilding, Sendable {
    typealias Extractor = BasicFeatureExtractor

    nonisolated func extractor(configuration: AudioFingerprintConfiguration) -> BasicFeatureExtractor {
        // BasicFeatureExtractor.init has no isolation annotation — this call
        // is safe from any nonisolated context.
        BasicFeatureExtractor(
            frameSize:    configuration.frameSize,
            hopSize:      configuration.hopSize,
            segmentCount: configuration.segmentCount
        )
    }
}
