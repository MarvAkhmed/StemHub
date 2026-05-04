//
//  AudioDecodingContext.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Captures all AVFoundation objects required for a single decode pass.
///
/// ## Thread-safety rationale
/// `AVAudioFile` and `AVAudioConverter` are Objective-C objects with no
/// `Sendable` conformance. This struct is marked `@unchecked Sendable`
/// because:
///
/// 1. `DefaultAVFoundationAudioPCMDecoder.decode(context:processChunk:)` is a
///    synchronous `nonisolated` function — the entire decode loop, including
///    every read on `audioFile` and every call to `converter`, happens
///    sequentially on a single thread with no concurrent access.
/// 2. The context is created immediately before the decode call and discarded
///    immediately after; it is never shared between concurrent tasks.
///
/// No `@unchecked Sendable` is added to the struct members themselves; the
/// safety guarantee is at the *usage* level, enforced by the single-threaded
/// decode loop.
struct AudioDecodingContext: @unchecked Sendable {
    let fileName: String
    let audioFile: AVAudioFile
    let inputFormat: AVAudioFormat
    let outputFormat: AVAudioFormat
    let converter: AVAudioConverter
    let inputFrameCapacity: AVAudioFrameCount
    let outputFrameCapacity: AVAudioFrameCount
    let maxOutputFrames: Int64
}
