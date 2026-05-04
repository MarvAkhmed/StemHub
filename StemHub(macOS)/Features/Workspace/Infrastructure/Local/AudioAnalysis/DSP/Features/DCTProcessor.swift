//
//  DCTProcessor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate
import Foundation

/// A sequence of Discrete Cosine Transform coefficients produced by `DCTProcessor`.
///
/// The first coefficient (index 0) is the DC term (mean energy).
/// Higher-index coefficients capture progressively finer spectral shape detail.
///
/// ## Sendable
/// All stored properties are value types; struct is unconditionally `Sendable`.
struct DCTCoefficients: Sendable {

    /// The DCT coefficient values. `values.count` equals `coefficientCount`.
    let values: [Float]

    /// The number of coefficients retained. This is at most the number of mel
    /// bands passed to `DCTProcessor.transform(_:coefficientCount:)`.
    let coefficientCount: Int
}

/// Applies a Discrete Cosine Transform to mel-band energies.
///
/// Renamed from `DCTTransforming` → `DCTProcessing` (LAW-D3).
/// Marked `Sendable` per LAW-C3.
protocol DCTProcessing: Sendable {
    /// Returns DCT coefficients for the given mel energies.
    ///
    /// - Parameters:
    ///   - melEnergies: The mel-band energy values to transform.
    ///   - coefficientCount: The number of DCT coefficients to return.
    /// - Throws: `AudioDSPError` on invalid inputs or Accelerate failure.
    func transform(_ melEnergies: MelEnergies, coefficientCount: Int) throws -> DCTCoefficients
}
/// Default implementation of `DCTProcessing`.
///
/// LAW-C1: struct — DCT transformation is stateless and deterministic.
/// vDSP.DCT objects are created per-call; they are lightweight for the
/// small band-counts used here (typically 26–40 bands).
/// LAW-C7: `Sendable` via struct + no stored mutable state.
struct DCTProcessor: DCTProcessing, Sendable {
    public init() {}

    public func transform(_ melEnergies: MelEnergies, coefficientCount: Int) throws -> DCTCoefficients {
        guard !melEnergies.values.isEmpty else {
            throw AudioDSPError.invalidBandCount(melEnergies.bandCount)
        }
        guard coefficientCount > 0 else {
            throw AudioDSPError.invalidCoefficientCount(coefficientCount)
        }

        let length = melEnergies.values.count
        guard let dct = vDSP.DCT(count: length, transformType: .II) else {
            throw AudioDSPError.dctSetupCreationFailed(length: length)
        }

        let output  = dct.transform(melEnergies.values)
        let bounded = min(coefficientCount, output.count)

        return DCTCoefficients(
            values: Array(output.prefix(bounded)),
            coefficientCount: bounded
        )
    }
}
