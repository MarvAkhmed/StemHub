//
//  ChromaProcessor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A 12-bin chroma (pitch-class) vector produced by `ChromaProcessor`.
///
/// Each bin represents the relative energy in one of the 12 pitch classes
/// of Western equal temperament (C, C#, D, D#, E, F, F#, G, G#, A, A#, B).
/// Values are normalised so that `values.reduce(0, +) ≈ 1` (or all zeros
/// for a silent frame).
///
/// ## Sendable
/// All stored properties are value types; struct is unconditionally `Sendable`.
struct ChromaVector: Sendable {

    /// 12 normalised pitch-class energy values.
    /// Index 0 → C, index 1 → C#, …, index 11 → B.
    let values: [Float]

    /// Always 12 in standard Western equal temperament.
    let binCount: Int

    /// The A4 reference frequency used to compute this vector, in Hz.
    let referenceFrequency: Double
}


/// Extracts a chroma vector from a magnitude spectrum.
///
/// Renamed from `ChromaExtracting` → `ChromaProcessing` (LAW-D3).
/// Marked `Sendable` per LAW-C3.
protocol ChromaProcessing: Sendable {
    /// Returns a chroma vector computed from `spectrum`.
    ///
    /// - Parameters:
    ///   - spectrum: The magnitude spectrum to analyse.
    ///   - referenceFrequency: The reference frequency for A4 in Hz.
    /// - Throws: `AudioDSPError` on invalid inputs.
    func chroma(from spectrum: MagnitudeSpectrum, referenceFrequency: Double) throws -> ChromaVector
}

/// Default implementation of `ChromaProcessing`.
///
/// LAW-C1: struct — chroma extraction is stateless and deterministic.
/// LAW-C7: `Sendable` via struct + no stored mutable state.
struct ChromaProcessor: ChromaProcessing, Sendable {
    public init() {}

    public func chroma(from spectrum: MagnitudeSpectrum,
                       referenceFrequency: Double = DSPConstants.defaultA4ReferenceFrequencyHz) throws -> ChromaVector {
        
        try validateInputs(spectrum: spectrum, referenceFrequency: referenceFrequency)

        var chroma = [Float](
            repeating: DSPConstants.zeroFloat,
            count: DSPConstants.chromaBinCount
        )
        let binSpan = Double(
            (spectrum.binCount - DSPConstants.firstNonDCBin)
            * DSPConstants.nyquistDivisor
        )

        for bin in DSPConstants.firstNonDCBin..<spectrum.binCount {
            let frequency = Double(bin) * spectrum.sampleRate / binSpan
            guard frequency > DSPConstants.zeroDouble else { continue }

            let midiNote = DSPConstants.semitonesPerOctave
                * log2(frequency / referenceFrequency)
                + DSPConstants.midiNoteForA4
            let pitchClass = normalizedPitchClass(from: midiNote)
            chroma[pitchClass] += spectrum.magnitudes[bin]
        }

        let total = chroma.reduce(DSPConstants.zeroFloat, +)
        if total > DSPConstants.zeroFloat {
            chroma = chroma.map { $0 / total }
        }

        return ChromaVector(
            values: chroma,
            binCount: DSPConstants.chromaBinCount,
            referenceFrequency: referenceFrequency
        )
    }

    // MARK: - Private

    private func validateInputs(
        spectrum: MagnitudeSpectrum,
        referenceFrequency: Double
    ) throws {
        guard spectrum.binCount > 1 else {
            throw AudioDSPError.invalidBinCount(spectrum.binCount)
        }
        guard spectrum.magnitudes.count == spectrum.binCount else {
            throw AudioDSPError.invalidSpectrumLength(spectrum.magnitudes.count)
        }
        guard spectrum.sampleRate > DSPConstants.zeroDouble else {
            throw AudioDSPError.invalidSampleRate(spectrum.sampleRate)
        }
        guard referenceFrequency > DSPConstants.zeroDouble else {
            throw AudioDSPError.invalidFrequencyRange(
                minimum: DSPConstants.zeroDouble,
                maximum: referenceFrequency
            )
        }
    }

    private func normalizedPitchClass(from midiNote: Double) -> Int {
        let rounded = Int(round(midiNote))
        return (rounded % DSPConstants.chromaBinCount
                + DSPConstants.chromaBinCount) % DSPConstants.chromaBinCount
    }
}
