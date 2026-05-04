//
//  AudioDSPError.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

import Foundation
import Accelerate

public enum AudioDSPError: Error, Equatable {
    case emptyFrame
    case frameLengthNotPowerOfTwo(length: Int)
    case invalidSampleRate(Double)
    case invalidFrequencyRange(minimum: Double, maximum: Double)
    case invalidBinCount(Int)
    case invalidBandCount(Int)
    case invalidCoefficientCount(Int)
    case invalidSpectrumLength(Int)
    case incompatibleSpectrumLengths(current: Int, previous: Int)
    case fftSetupCreationFailed(log2Length: vDSP_Length)
    case fftSetupLengthMismatch(expected: vDSP_Length, actual: vDSP_Length)
    case dctSetupCreationFailed(length: Int)
    case dctSetupUnavailable(length: Int)
    case unsafeBufferAccessFailed
}
