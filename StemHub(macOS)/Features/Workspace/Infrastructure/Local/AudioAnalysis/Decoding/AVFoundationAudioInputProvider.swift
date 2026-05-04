//
//  AVFoundationAudioInputProvider.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Implements `AVFoundationAudioInputProviding` by reading successive frames
/// from an `AVAudioFile` stored in an `AudioDecodingContext`.
///
/// ## Why a class?
/// `AVAudioConverter.convert(to:error:inputBlock:)` calls its input block
/// multiple times per conversion step. Each call must observe and update
/// shared state (`reachedEndOfStream`, `readError`). A class provides the
/// reference semantics required for the closure to capture and mutate this
/// state correctly across calls. This is the Objective-C bridging exception
/// permitted by LAW-C1.
///
/// ## Isolation
/// This class is explicitly NOT isolated to any actor. All methods and
/// properties are `nonisolated`. The decode loop that uses this class runs
/// entirely on a single cooperative thread inside a `nonisolated` synchronous
/// function — no actor hopping occurs, no concurrent access is possible.
final class AVFoundationAudioInputProvider: AVFoundationAudioInputProviding {

    // MARK: - Dependencies

    private let context: AudioDecodingContext

    // MARK: - Mutable state
    // Accessed only from the single-threaded synchronous decode loop.
    // No locking required — see class-level doc comment.

    private var reachedEndOfStream = false

    /// Satisfies `AVFoundationAudioInputProviding.readError`.
    ///
    /// Explicitly `nonisolated` so `DefaultAudioConverterRunner` can read it
    /// from a `nonisolated` context without a concurrency warning.
    nonisolated(unsafe) private(set) var readError: Error?

    // MARK: - Init

    /// Creates an input provider for the given decoding context.
    ///
    /// Explicitly `nonisolated` so `DefaultAVFoundationAudioPCMDecoder` can
    /// call it from a `nonisolated` synchronous function without actor hopping.
    nonisolated init(context: AudioDecodingContext) {
        self.context = context
    }

    // MARK: - AVFoundationAudioInputProviding

    func provideInput(
        outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>
    ) -> AVAudioBuffer? {
        guard canProvideInput(outStatus: outStatus) else { return nil }
        return readNextInputBuffer(outStatus: outStatus)
    }

    // MARK: - Private

    private func canProvideInput(
        outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>
    ) -> Bool {
        if readError != nil {
            outStatus.pointee = .noDataNow
            return false
        }
        if reachedEndOfStream {
            outStatus.pointee = .endOfStream
            return false
        }
        return true
    }

    private func readNextInputBuffer(
        outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>
    ) -> AVAudioBuffer? {
        guard let inputBuffer = allocateInputBuffer(outStatus: outStatus) else {
            return nil
        }
        return readFrames(into: inputBuffer, outStatus: outStatus)
    }

    private func allocateInputBuffer(
        outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>
    ) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: context.inputFormat,
            frameCapacity: context.inputFrameCapacity
        ) else {
            readError = AudioAnalysisImplementationError.decodeFailed(
                "Failed to allocate an input PCM buffer for '\(context.fileName)'."
            )
            outStatus.pointee = .noDataNow
            return nil
        }
        return buffer
    }

    private func readFrames(
        into buffer: AVAudioPCMBuffer,
        outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>
    ) -> AVAudioBuffer? {
        do {
            try context.audioFile.read(
                into: buffer,
                frameCount: context.inputFrameCapacity
            )
        } catch {
            readError = error
            outStatus.pointee = .noDataNow
            return nil
        }

        guard buffer.frameLength > 0 else {
            reachedEndOfStream = true
            outStatus.pointee  = .endOfStream
            return nil
        }

        outStatus.pointee = .haveData
        return buffer
    }
}
