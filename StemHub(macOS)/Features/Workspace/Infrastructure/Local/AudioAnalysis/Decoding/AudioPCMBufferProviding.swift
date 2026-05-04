//
//  AudioPCMBufferProviding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Allocates `AVAudioPCMBuffer` instances.
///
/// Renamed from `AudioPCMBufferMaking` → `AudioPCMBufferProviding` (LAW-D3).
protocol AudioPCMBufferProviding: Sendable {
    /// Allocates and returns a PCM buffer.
    ///
    /// - Parameters:
    ///   - format: The PCM format for the buffer.
    ///   - frameCapacity: The frame capacity to reserve.
    ///   - fileName: Used only for error messages.
    /// - Throws: `AudioAnalysisImplementationError.decodeFailed` when
    ///   allocation fails.
    nonisolated func buffer(format: AVAudioFormat,
                            frameCapacity: AVAudioFrameCount, fileName: String) throws -> AVAudioPCMBuffer
}
