//
//  LoudnessMeasurement.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Loudness characteristics for a single DSP frame, produced by `LoudnessProcessor`.
///
/// ## Sendable
/// All stored properties are value types; struct is unconditionally `Sendable`.
struct LoudnessMeasurement: Sendable {

    /// Root-mean-square energy of the frame.
    ///
    /// RMS is proportional to the perceived loudness of the frame. A value of 0
    /// indicates digital silence; a value of 1.0 indicates full-scale energy.
    let rootMeanSquare: Float

    /// Peak absolute magnitude of any sample in the frame.
    let peakMagnitude: Float

    /// `true` when `rootMeanSquare` is below the configured silence threshold.
    ///
    /// Silent frames are typically excluded from feature accumulation to avoid
    /// polluting fingerprint vectors with silence statistics.
    let isBelowSilenceThreshold: Bool
}
