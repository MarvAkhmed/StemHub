//
//  AudioConverterProcessing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Executes a single `AVAudioConverter` conversion pass.
///
/// Renamed from `AudioConverterRunning` → `AudioConverterProcessing` (LAW-D3).
protocol AudioConverterProcessing: Sendable {
    /// Runs one conversion step and returns the output status.
    ///
    /// - Parameters:
    ///   - converter: The converter to use.
    ///   - outputBuffer: The buffer to fill.
    ///   - inputProvider: The source of raw PCM data.
    /// - Returns: The `AVAudioConverterOutputStatus` from the conversion.
    /// - Throws: `AudioAnalysisImplementationError.decodeFailed` on error.
    nonisolated func convert(converter: AVAudioConverter, outputBuffer: AVAudioPCMBuffer,
                             inputProvider: AVFoundationAudioInputProviding) throws -> AVAudioConverterOutputStatus
}
