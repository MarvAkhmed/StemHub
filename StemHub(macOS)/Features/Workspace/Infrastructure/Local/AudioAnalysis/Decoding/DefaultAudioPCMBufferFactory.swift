//
//  DefaultAudioPCMBufferFactory.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioPCMBufferProviding`.
struct DefaultAudioPCMBufferFactory: AudioPCMBufferProviding {
    nonisolated func buffer(format: AVAudioFormat, frameCapacity: AVAudioFrameCount, fileName: String) throws -> AVAudioPCMBuffer {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Failed to allocate a PCM buffer for '\(fileName)'."
            )
        }
        return buffer
    }
}
