//
//  AudioConverterBuilding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Creates `AVAudioConverter` instances.
///
/// Renamed from `AudioConverterMaking` → `AudioConverterBuilding` (LAW-D3).
protocol AudioConverterBuilding: Sendable {
    /// Creates and returns an `AVAudioConverter` from `inputFormat` to `outputFormat`.
    ///
    /// - Parameters:
    ///   - inputFormat: The source audio format.
    ///   - outputFormat: The target audio format.
    ///   - fileName: Used only for error messages.
    /// - Throws: `AudioAnalysisImplementationError.decodeFailed` when the
    ///   converter cannot be created.
    nonisolated func converter(from inputFormat: AVAudioFormat,
                               to outputFormat: AVAudioFormat, fileName: String) throws -> AVAudioConverter
}
