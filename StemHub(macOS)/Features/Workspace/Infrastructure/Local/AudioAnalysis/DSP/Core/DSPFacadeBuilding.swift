//
//  DSPFacadeBuilding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Constructs a fully wired `AudioDSPFacade` and its pre-computed `MelFilterbank`.
///
/// This protocol exists so that fingerprinting engines receive the entire DSP
/// stack through dependency injection rather than constructing it internally.
/// Test doubles can supply lightweight or deterministic DSP stacks without
/// touching production Accelerate code.
///
/// LAW-D3: `Building` suffix — approved.
/// LAW-C3: `Sendable` — implementations are stored in nonisolated async paths.
protocol DSPFacadeBuilding: Sendable {
    /// Constructs and returns an `AudioDSPFacade` paired with a `MelFilterbank`.
    ///
    /// - Parameters:
    ///   - frameSize: The FFT frame size in samples (must be a power of 2).
    ///   - targetSampleRate: The decode target sample rate in Hz.
    ///   - melBands: The number of mel filterbank bands.
    ///   - silenceThreshold: RMS threshold below which frames are silent.
    /// - Returns: A tuple of the fully configured facade and filterbank.
    /// - Throws: `AudioDSPError` on Accelerate setup failure.
    func build(frameSize: Int, targetSampleRate: Double,
               melBands: Int, silenceThreshold: Float) throws -> (facade: AudioDSPFacade, filterbank: MelFilterbank)
}
