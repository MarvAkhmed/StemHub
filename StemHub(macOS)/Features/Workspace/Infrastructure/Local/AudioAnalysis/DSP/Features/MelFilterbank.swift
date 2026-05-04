//
//  MelFilterbank.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A triangular mel filterbank matrix produced by `MelFilterbankBuilder`.
///
/// Apply the filterbank to a `MagnitudeSpectrum` by multiplying each filter
/// row against the magnitude vector to obtain per-band energy values.
///
/// ## Sendable
/// All stored properties are value types; struct is unconditionally `Sendable`.
struct MelFilterbank: Sendable {

    /// Filter coefficients organised as `[bandIndex][binIndex]`.
    /// Dimensions: `bandCount × binCount`.
    let filters: [[Float]]

    /// Number of mel bands (rows in `filters`).
    let bandCount: Int

    /// Number of FFT bins (columns in `filters`). Must equal the `binCount`
    /// of every `MagnitudeSpectrum` this filterbank is applied to.
    let binCount: Int

    /// The sample rate for which this filterbank was constructed.
    let sampleRate: Double

    /// The lower frequency bound of the first filter in Hz.
    let minimumFrequency: Double

    /// The upper frequency bound of the last filter in Hz.
    let maximumFrequency: Double

    // MARK: - Application

    /// Applies the filterbank to a magnitude spectrum and returns per-band energies.
    ///
    /// - Parameter spectrum: The magnitude spectrum to filter.
    ///   Its `binCount` must equal this filterbank's `binCount`.
    /// - Returns: An array of `bandCount` energy values.
    func apply(to spectrum: MagnitudeSpectrum) -> [Float] {
        precondition(
            spectrum.binCount == binCount,
            "MelFilterbank.apply: spectrum.binCount (\(spectrum.binCount)) "
            + "≠ filterbank.binCount (\(binCount))."
        )
        return filters.map { filter in
            zip(filter, spectrum.magnitudes).reduce(0.0) { $0 + $1.0 * $1.1 }
        }
    }
}
