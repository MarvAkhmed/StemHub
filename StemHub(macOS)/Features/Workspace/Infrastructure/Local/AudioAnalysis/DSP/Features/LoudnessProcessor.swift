//
//  LoudnessProcessor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate
import Foundation

/// Computes RMS and peak loudness measurements from a DSP frame.
///
/// Renamed from `LoudnessAnalysing` → `LoudnessProcessing` (LAW-D3).
/// Marked `Sendable` per LAW-C3.
///
/// - Note: This file intentionally contains only the protocol declaration.
///   The concrete implementation lives in `LoudnessProcessor.swift`.
///   This separates the contract from the implementation (LAW-N1).
protocol LoudnessProcessing: Sendable {
    /// Analyses the loudness characteristics of a validated DSP frame.
    ///
    /// - Parameter frame: A validated `DSPFrame`.
    /// - Returns: A `LoudnessMeasurement` containing RMS, peak, and silence flag.
    /// - Throws: `AudioDSPError` on parameter failure.
    func analyse(_ frame: DSPFrame) throws -> LoudnessMeasurement
}


/// Default implementation of `LoudnessProcessing`.
///
/// LAW-C1: struct — loudness analysis is stateless apart from the immutable
///   `silenceThreshold` configuration value.
/// LAW-N1: Separated from `LoudnessProcessing.swift`. The original file
///   contained both the `LoudnessAnalysing` protocol and `VDSPFFTProcessor`
///   — two unrelated primary types in one file. Both violations are fixed:
///   the protocol lives in `LoudnessProcessing.swift` and this implementation
///   lives here.
/// LAW-C7: `Sendable` via struct + all stored properties are `Sendable`.
struct LoudnessProcessor: LoudnessProcessing, Sendable {

    // MARK: - Configuration

    private let silenceThreshold: Float

    // MARK: - Init

    /// - Parameter silenceThreshold: RMS threshold below which audio is
    ///   considered silent. Defaults to `DSPConstants.defaultSilenceThreshold`.
    public init(silenceThreshold: Float = DSPConstants.defaultSilenceThreshold) {
        self.silenceThreshold = silenceThreshold
    }

    // MARK: - LoudnessProcessing

    public func analyse(_ frame: DSPFrame) throws -> LoudnessMeasurement {
        let rms  = rootMeanSquare(frame)
        let peak = peakMagnitude(frame)

        return LoudnessMeasurement(
            rootMeanSquare: rms,
            peakMagnitude: peak,
            isBelowSilenceThreshold: rms < silenceThreshold
        )
    }

    // MARK: - Private vDSP helpers

    private func rootMeanSquare(_ frame: DSPFrame) -> Float {
        var sumOfSquares = DSPConstants.zeroFloat
        vDSP_svesq(
            frame.samples, 1,
            &sumOfSquares,
            vDSP_Length(frame.length)
        )
        return sqrt(sumOfSquares / Float(frame.length))
    }

    private func peakMagnitude(_ frame: DSPFrame) -> Float {
        var result = DSPConstants.zeroFloat
        vDSP_maxmgv(
            frame.samples, 1,
            &result,
            vDSP_Length(frame.length)
        )
        return result
    }
}
