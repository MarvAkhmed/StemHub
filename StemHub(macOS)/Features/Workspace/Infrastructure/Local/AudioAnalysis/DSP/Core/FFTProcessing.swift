//
//  FFTProcessing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate

/// Computes a magnitude spectrum from a validated DSP frame.
///
/// Renamed from `FFTAnalysing` → `FFTProcessing` (LAW-D3: approved suffix).
/// Marked `Sendable` per LAW-C3.
protocol FFTProcessing: Sendable {
    /// Returns the magnitude spectrum for the given DSP frame.
    ///
    /// - Parameter frame: A validated `DSPFrame`.
    /// - Returns: A `MagnitudeSpectrum` containing one magnitude per bin.
    /// - Throws: `AudioDSPError` on any Accelerate or parameter failure.
    func magnitudeSpectrum(for frame: DSPFrame) throws -> MagnitudeSpectrum
}
