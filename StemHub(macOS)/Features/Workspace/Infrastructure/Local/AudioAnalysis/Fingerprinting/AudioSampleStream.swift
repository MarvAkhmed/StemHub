//
//  AudioSampleStream.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A paired AsyncThrowingStream and its continuation used to pipeline
/// decoded PCM samples between a producer task and a consumer task.
///
/// - Note: Both `stream` and `continuation` are `Sendable` by their own
///   declarations, so this struct is safely `Sendable`.
struct AudioSampleStream: Sendable {
    let stream: AsyncThrowingStream<[Float], Error>
    let continuation: AsyncThrowingStream<[Float], Error>.Continuation
}
