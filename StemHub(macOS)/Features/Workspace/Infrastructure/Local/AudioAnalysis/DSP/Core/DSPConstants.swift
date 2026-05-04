//
//  DSPConstants.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate
import Foundation

/// Compile-time numeric constants for the DSP layer.
///
/// LAW-D1: Caseless enum — prevents instantiation, holds no static stored state.
///   Every value is a `static let` computed once and never mutated.
/// LAW-N1: One primary type per file.
enum DSPConstants {

    // MARK: - Zero sentinels
    // Named sentinels make intent explicit and avoid magic literals throughout
    // the DSP layer.

    /// `Float` zero used as a vDSP fill value and comparison baseline.
    static let zeroFloat: Float = 0.0

    /// `Double` zero used in guard conditions throughout the DSP layer.
    static let zeroDouble: Double = 0.0

    /// `Double` one used in Mel-scale arithmetic.
    static let oneDouble: Double = 1.0

    // MARK: - FFT layout

    /// The Nyquist divisor (2). The real FFT of an N-point frame produces
    /// N/2 independent complex bins.
    static let nyquistDivisor: Int = 2

    /// Index of the first non-DC bin in a real FFT output (bin 1).
    static let firstNonDCBin: Int = 1

    /// Scaling numerator applied after the vDSP real FFT to obtain physical
    /// magnitudes. vDSP's `FFT_FORWARD` returns values scaled by 2 relative
    /// to a normalised DFT, so the correct scale factor is `2 / N`.
    static let fftScaleNumerator: Float = 2.0

    // MARK: - Mel filterbank

    /// Standard reference frequency for the Mel scale (700 Hz).
    /// Source: O'Shaughnessy, D. (1987). *Speech Communication.*
    static let melReferenceFrequencyHz: Double = 700.0

    /// Mel scale multiplier (2595). Converts Hz to Mel via
    /// `mel = 2595 × log₁₀(1 + f / 700)`.
    static let melScaleMultiplier: Double = 2_595.0

    /// Default lower frequency bound for the mel filterbank (80 Hz).
    /// Values below ~80 Hz contain little musical content and excessive noise.
    static let defaultMinimumFrequencyHz: Double = 80.0

    // MARK: - Chroma

    /// Number of pitch classes in Western equal temperament (12).
    static let chromaBinCount: Int = 12

    /// Number of semitones per octave (12.0, as `Double` for log2 arithmetic).
    static let semitonesPerOctave: Double = 12.0

    /// MIDI note number for A4 (69). Used as the origin for pitch-class mapping.
    static let midiNoteForA4: Double = 69.0

    /// Default concert-pitch reference frequency for A4 (440.0 Hz).
    static let defaultA4ReferenceFrequencyHz: Double = 440.0

    // MARK: - Loudness

    /// Default RMS threshold below which a frame is classified as silent.
    /// Frames with RMS below this value are excluded from feature accumulation.
    static let defaultSilenceThreshold: Float = 0.001
}
