//
//  AudioSampleStreamFactory.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Creates `AudioSampleStream` instances for the fingerprinting and hashing pipelines.
///
/// Caseless enum — prevents instantiation, no static stored state (LAW-D1).
/// Every call to `makeStream()` produces an independent stream/continuation pair.
enum AudioSampleStreamFactory {

    /// Returns a new `AudioSampleStream` backed by a fresh `AsyncThrowingStream`.
    ///
    /// - Returns: An `AudioSampleStream` whose `stream` has not yet been
    ///   iterated and whose `continuation` has not yet been written to.
    nonisolated static func makeStream() -> AudioSampleStream {
        let (stream, continuation) = AsyncThrowingStream<[Float], Error>.makeStream()
        return AudioSampleStream(stream: stream, continuation: continuation)
    }
}
