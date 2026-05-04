//
//  AudioPCMFormatProviding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Creates `AVAudioFormat` instances for PCM output buffers.
///
/// Renamed from `AudioPCMFormatMaking` → `AudioPCMFormatProviding`
/// to satisfy the approved `-Providing` suffix (LAW-D3).
protocol AudioPCMFormatProviding: Sendable {
    /// Returns a mono Float32 non-interleaved `AVAudioFormat`.
    ///
    /// - Parameters:
    ///   - sampleRate: The target sample rate in Hz.
    ///   - fileName: Used only for error messages.
    /// - Throws: `AudioAnalysisImplementationError.decodeFailed` when the
    ///   format cannot be created.
    nonisolated func monoFloat32Format(sampleRate: Double, fileName: String) throws -> AVAudioFormat
}
