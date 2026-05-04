//
//  DefaultAudioPCMFormatFactory.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioPCMFormatProviding`.
struct DefaultAudioPCMFormatFactory: AudioPCMFormatProviding {
    nonisolated func monoFloat32Format(sampleRate: Double, fileName: String) throws -> AVAudioFormat {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 1,
                                         interleaved: false) else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Failed to create a mono Float32 PCM format for '\(fileName)'."
            )
        }
        return format
    }
}
