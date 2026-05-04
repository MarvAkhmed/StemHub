//
//  AudioSampleProviding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Extracts a `[Float]` sample array from a decoded `AVAudioPCMBuffer`.
///
/// Renamed from `AudioSampleExtracting` → `AudioSampleProviding` (LAW-D3).
protocol AudioSampleProviding: Sendable {
    /// Extracts up to `maxOutputFrames - emittedFrames` frames from `buffer`.
    ///
    /// - Parameters:
    ///   - buffer: The decoded PCM buffer.
    ///   - emittedFrames: The number of frames already emitted in this decode pass.
    ///   - maxOutputFrames: The maximum total frames to emit.
    ///   - fileName: Used only for error messages.
    /// - Returns: An array of `Float` samples, possibly empty if the frame cap
    ///   has been reached.
    /// - Throws: `AudioAnalysisImplementationError.decodeFailed` when the
    ///   buffer's channel data is unavailable.
    nonisolated func samples(from buffer: AVAudioPCMBuffer, emittedFrames: Int64,
                             maxOutputFrames: Int64, fileName: String) throws -> [Float]
}
