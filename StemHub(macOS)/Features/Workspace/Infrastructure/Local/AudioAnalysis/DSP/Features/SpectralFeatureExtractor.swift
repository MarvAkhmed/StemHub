//
//  SpectralFeatureExtractor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation


/// Extracts low-level spectral features from magnitude spectra.
///
/// Renamed from `SpectralAnalysing` → `SpectralProcessing` (LAW-D3).
/// Marked `Sendable` per LAW-C3.
protocol SpectralProcessing: Sendable {
    /// Computes spectral centroid and optional spectral flux.
    ///
    /// - Parameters:
    ///   - current: The magnitude spectrum for the current frame.
    ///   - previous: The magnitude spectrum for the preceding frame, used
    ///     to compute spectral flux. Pass `nil` for the first frame.
    /// - Returns: A `SpectralFeatures` value containing centroid and flux.
    /// - Throws: `AudioDSPError` on invalid or mismatched spectra.
    func extractFeatures(current: MagnitudeSpectrum, previous: MagnitudeSpectrum?) throws -> SpectralFeatures
}


/// Default implementation of `SpectralProcessing`.
///
/// LAW-C1: struct — spectral feature extraction is stateless and deterministic.
/// LAW-C7: `Sendable` via struct + no stored mutable state.
struct SpectralFeatureExtractor: SpectralProcessing, Sendable {
    public init() {}

    public func extractFeatures(current: MagnitudeSpectrum, previous: MagnitudeSpectrum?) throws -> SpectralFeatures {
        try validateSpectrum(current)

        if let previous {
            try validateSpectrum(previous)
            guard current.binCount == previous.binCount else {
                throw AudioDSPError.incompatibleSpectrumLengths(
                    current: current.binCount,
                    previous: previous.binCount
                )
            }
        }

        let centroid = spectralCentroid(from: current)
        let flux     = previous.map { spectralFlux(current: current, previous: $0) }

        return SpectralFeatures(centroid: centroid, flux: flux)
    }

    // MARK: - Private helpers

    private func validateSpectrum(_ spectrum: MagnitudeSpectrum) throws {
        guard spectrum.binCount > 1 else {
            throw AudioDSPError.invalidBinCount(spectrum.binCount)
        }
        guard spectrum.magnitudes.count == spectrum.binCount else {
            throw AudioDSPError.invalidSpectrumLength(spectrum.magnitudes.count)
        }
    }

    private func spectralCentroid(from spectrum: MagnitudeSpectrum) -> Float {
        var weighted = DSPConstants.zeroFloat
        var total    = DSPConstants.zeroFloat

        for bin in 0..<spectrum.binCount {
            let mag   = spectrum.magnitudes[bin]
            weighted += Float(bin) * mag
            total    += mag
        }

        guard total > DSPConstants.zeroFloat else { return DSPConstants.zeroFloat }
        return weighted / (total * Float(spectrum.binCount - DSPConstants.firstNonDCBin))
    }

    private func spectralFlux(current: MagnitudeSpectrum, previous: MagnitudeSpectrum) -> Float {
        var flux = DSPConstants.zeroFloat
        for bin in 0..<current.binCount {
            flux += max(
                DSPConstants.zeroFloat,
                current.magnitudes[bin] - previous.magnitudes[bin]
            )
        }
        return flux
    }
}
