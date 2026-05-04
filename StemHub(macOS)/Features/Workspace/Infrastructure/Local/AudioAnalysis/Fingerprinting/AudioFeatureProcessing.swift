//
//  AudioFeatureProcessing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A stateful feature accumulator that ingests sample chunks and produces
/// a `BasicAudioFingerprint` on demand.
///
/// Renamed from `AudioFeatureExtracting` → `AudioFeatureProcessing` (LAW-D3).
///
/// ## Concurrency model
/// `AudioFeatureProcessing` conformers are `Sendable` value types (`struct`).
/// The fingerprinting pipeline creates one extractor per fingerprint operation,
/// mutates it inside a single `Task`, and never shares it across tasks.
/// This avoids any need for locking or actors on the extractor itself.
protocol AudioFeatureProcessing: Sendable {
    /// Accumulates a decoded sample chunk into the extractor's internal state.
    ///
    /// - Parameter samples: A chunk of decoded mono float32 samples.
    mutating func consume(_ samples: [Float])

    /// Finalises analysis and returns a completed fingerprint.
    ///
    /// - Parameter fileName: Used only for error messages.
    /// - Returns: A completed `BasicAudioFingerprint`.
    /// - Throws: `AudioAnalysisImplementationError` when no frames were decoded
    ///   or the resulting feature vector is degenerate.
    mutating func makeFingerprint(fileName: String) throws -> BasicAudioFingerprint
}
