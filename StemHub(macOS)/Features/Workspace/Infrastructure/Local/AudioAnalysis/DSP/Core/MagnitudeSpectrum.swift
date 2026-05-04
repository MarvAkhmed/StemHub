//
//  MagnitudeSpectrum.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// The one-sided magnitude spectrum produced by a real FFT.
///
/// For an N-sample frame the spectrum contains N/2 + 1 bins:
///   - Bin 0:       DC component  (0 Hz)
///   - Bins 1…N/2-1: positive frequencies
///   - Bin N/2:     Nyquist component  (sampleRate / 2 Hz)
///
/// ## Sendable
/// All stored properties are value types; struct is unconditionally `Sendable`.
struct MagnitudeSpectrum: Sendable {

    /// One magnitude value per frequency bin.
    /// `magnitudes.count` equals `binCount`.
    let magnitudes: [Float]

    /// Number of frequency bins (N/2 + 1 for an N-sample frame).
    let binCount: Int

    /// The sample rate of the audio that was analysed, in Hz.
    /// Used to convert bin indices to frequencies: `frequency = bin × sampleRate / (2 × (binCount − 1))`.
    let sampleRate: Double
}
