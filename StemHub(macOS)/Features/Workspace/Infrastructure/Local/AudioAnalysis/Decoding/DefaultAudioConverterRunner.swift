//
//  DefaultAudioConverterRunner.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioConverterProcessing`.
///
/// Runs one `AVAudioConverter.convert(to:error:inputBlock:)` step and
/// surfaces any errors from either the converter or the input provider.
///
/// ## Thread safety
/// This struct is `nonisolated`. It is called from the synchronous decode
/// loop inside `DefaultAVFoundationAudioPCMDecoder`, which runs entirely on
/// one cooperative thread. `inputProvider` is a reference-type object whose
/// mutable state is only ever accessed from that single thread.
struct DefaultAudioConverterRunner: AudioConverterProcessing {

    nonisolated func convert(
        converter: AVAudioConverter,
        outputBuffer: AVAudioPCMBuffer,
        inputProvider: AVFoundationAudioInputProviding
    ) throws -> AVAudioConverterOutputStatus {

        var conversionError: NSError?

        // The input block closure captures `inputProvider`.
        // `AVFoundationAudioInputProviding` is an AnyObject protocol (class-bound).
        // The closure is called synchronously and repeatedly by AVAudioConverter
        // on the same thread — no concurrent access occurs.
        // `@Sendable` is required by the AVAudioConverter API; we suppress the
        // Sendable warning with an explicit type annotation because the usage
        // is provably single-threaded (see class-level doc on the provider).
        let status = converter.convert(
            to: outputBuffer,
            error: &conversionError
        ) { [inputProvider] _, outStatus in
            inputProvider.provideInput(outStatus: outStatus)
        }

        // Read `readError` via the `nonisolated` protocol requirement.
        // This is safe because the closure above has already returned and
        // the converter is done calling the input block.
        if let readError = inputProvider.readError {
            throw readError
        }

        if let nsError = conversionError {
            throw AudioAnalysisImplementationError.decodeFailed(
                nsError.localizedDescription
            )
        }

        return status
    }
}
