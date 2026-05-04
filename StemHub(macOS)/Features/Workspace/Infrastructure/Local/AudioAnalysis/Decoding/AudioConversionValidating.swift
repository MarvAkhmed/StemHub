//
//  AudioConversionValidating.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Validates the output status of an `AVAudioConverter` conversion pass.
///
/// Renamed from `AudioConversionStatusHandling` → `AudioConversionValidating`
/// (LAW-D3: approved suffix family).
protocol AudioConversionValidating: Sendable {
    /// Inspects `status` and throws if it indicates a conversion failure.
    ///
    /// - Parameters:
    ///   - status: The status returned by `AVAudioConverter.convert(to:error:inputBlock:)`.
    ///   - fileName: Used only for error messages.
    /// - Throws: `AudioAnalysisImplementationError.decodeFailed` on error or
    ///   unknown status.
    nonisolated func validate(_ status: AVAudioConverterOutputStatus, fileName: String) throws
}
