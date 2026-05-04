//
//  WindowFunction.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate
import Foundation

/// Window functions applied to DSP frames before FFT computation.
///
/// Enum: the supported window types form a closed, finite set of DSP variants.
/// `Sendable` because enum cases with no associated values are trivially so.
enum WindowFunction: Sendable {
    case hann
    case hamming
    case blackman

    // MARK: - Public interface

    /// Applies this window function to a validated DSP frame.
    ///
    /// - Parameter frame: The validated `DSPFrame` to window.
    /// - Returns: A new array of `Float` samples with the window applied.
    public func apply(to frame: DSPFrame) -> [Float] {
        let window = coefficients(length: frame.length)
        var output = [Float](repeating: DSPConstants.zeroFloat, count: frame.length)
        vDSP_vmul(
            frame.samples, 1,
            window, 1,
            &output, 1,
            vDSP_Length(frame.length)
        )
        return output
    }

    // MARK: - Private coefficient generators

    private func coefficients(length: Int) -> [Float] {
        switch self {
        case .hann:     return hannCoefficients(length: length)
        case .hamming:  return hammingCoefficients(length: length)
        case .blackman: return blackmanCoefficients(length: length)
        }
    }

    private func hannCoefficients(length: Int) -> [Float] {
        var w = [Float](repeating: DSPConstants.zeroFloat, count: length)
        vDSP_hann_window(&w, vDSP_Length(length), Int32(vDSP_HANN_NORM))
        return w
    }

    private func hammingCoefficients(length: Int) -> [Float] {
        var w = [Float](repeating: DSPConstants.zeroFloat, count: length)
        vDSP_hamm_window(&w, vDSP_Length(length), 0)
        return w
    }

    private func blackmanCoefficients(length: Int) -> [Float] {
        var w = [Float](repeating: DSPConstants.zeroFloat, count: length)
        vDSP_blkman_window(&w, vDSP_Length(length), 0)
        return w
    }
}
