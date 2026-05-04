//
//  DefaultAudioConversionStatusHandler.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioConversionValidating`.
struct DefaultAudioConversionStatusHandler: AudioConversionValidating {
    nonisolated func validate(_ status: AVAudioConverterOutputStatus, fileName: String) throws {
        switch status {
        case .haveData, .inputRanDry, .endOfStream:
            return

        case .error:
            throw AudioAnalysisImplementationError.decodeFailed(
                "Audio conversion failed for '\(fileName)'."
            )

        @unknown default:
            throw AudioAnalysisImplementationError.decodeFailed(
                "Audio conversion returned an unknown status for '\(fileName)'."
            )
        }
    }
}
