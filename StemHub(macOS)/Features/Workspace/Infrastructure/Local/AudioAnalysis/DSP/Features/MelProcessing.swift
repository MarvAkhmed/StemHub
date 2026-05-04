//
//  MelProcessing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Builds triangular mel filterbanks.
///
/// Renamed from `MelFiltering` → `MelProcessing` (LAW-D3).
/// Marked `Sendable` per LAW-C3.
protocol MelProcessing: Sendable {
    /// Returns a triangular mel filterbank for the given parameters.
    ///
    /// - Parameters:
    ///   - bandCount: The number of mel bands.
    ///   - binCount: The number of FFT bins (typically frameSize / 2 + 1).
    ///   - sampleRate: The sample rate of the audio in Hz.
    ///   - minimumFrequency: The lower frequency bound of the filterbank in Hz.
    ///   - maximumFrequency: The upper frequency bound in Hz, or `nil` to
    ///     default to the Nyquist frequency.
    /// - Throws: `AudioDSPError` on invalid parameter combinations.
    func makeFilterbank(bandCount: Int, binCount: Int,
                        sampleRate: Double, minimumFrequency: Double,
                        maximumFrequency: Double?) throws -> MelFilterbank
}
