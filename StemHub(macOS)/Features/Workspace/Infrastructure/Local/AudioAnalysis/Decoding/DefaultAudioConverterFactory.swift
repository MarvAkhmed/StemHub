//
//  DefaultAudioConverterFactory.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioConverterBuilding`.
struct DefaultAudioConverterFactory: AudioConverterBuilding {
    nonisolated func converter(from inputFormat: AVAudioFormat,
                               to outputFormat: AVAudioFormat, fileName: String ) throws -> AVAudioConverter {
        
        guard let converter = AVAudioConverter(from: inputFormat,to: outputFormat) else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Failed to create an audio converter for '\(fileName)'."
            )
        }
        return converter
    }
}
