//
//  AudioDecodingContextBuilding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Builds an `AudioDecodingContext` for a given audio file URL.
///
/// - Note: `Sendable` because the protocol is used from `nonisolated` contexts.
protocol AudioDecodingContextBuilding: Sendable {
    /// Creates an `AudioDecodingContext` for the audio file at `url`.
    ///
    /// - Parameters:
    ///   - url: The URL of the audio file (caller must pass `.standardizedFileURL`).
    ///   - sampleRate: The desired output sample rate in Hz.
    ///   - maxDuration: Optional maximum duration to decode in seconds.
    /// - Returns: A fully initialised `AudioDecodingContext`.
    /// - Throws: `AudioAnalysisImplementationError.decodeFailed` on any
    ///   AVFoundation failure.
    nonisolated func context(for url: URL, sampleRate: Double, maxDuration: TimeInterval?) throws -> AudioDecodingContext
}
