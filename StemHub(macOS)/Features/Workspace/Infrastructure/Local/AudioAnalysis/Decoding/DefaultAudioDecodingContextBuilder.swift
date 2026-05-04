//
//  DefaultAudioDecodingContextBuilder.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioDecodingContextBuilding`.
///
/// Constructs an `AudioDecodingContext` by:
/// 1. Validating the requested sample rate.
/// 2. Opening the audio file with AVFoundation.
/// 3. Creating the mono-Float32 output format.
/// 4. Creating the `AVAudioConverter`.
/// 5. Computing frame capacities and the maximum output frame count.
///
/// All dependencies are injected; no concrete types are constructed internally.
struct DefaultAudioDecodingContextBuilder: AudioDecodingContextBuilding {

    // MARK: - Dependencies

    private let outputFrameCapacity: AVAudioFrameCount
    private let formatFactory: any AudioPCMFormatProviding
    private let converterFactory: any AudioConverterBuilding

    // MARK: - Init

    init(
        outputFrameCapacity: AVAudioFrameCount,
        formatFactory: any AudioPCMFormatProviding,
        converterFactory: any AudioConverterBuilding
    ) {
        self.outputFrameCapacity = outputFrameCapacity
        self.formatFactory       = formatFactory
        self.converterFactory    = converterFactory
    }

    // MARK: - AudioDecodingContextBuilding

    nonisolated func context(for url: URL, sampleRate: Double, maxDuration: TimeInterval?) throws -> AudioDecodingContext {
        // Validate before opening file handles.
        try validateSampleRate(sampleRate)

        // LAW-I3: Always standardize the URL before passing to AVFoundation.
        let standardizedURL = url.standardizedFileURL

        let audioFile    = try openAudioFile(at: standardizedURL)
        let inputFormat  = audioFile.processingFormat
        let outputFormat = try formatFactory.monoFloat32Format(
            sampleRate: sampleRate,
            fileName: standardizedURL.lastPathComponent
        )
        let converter = try converterFactory.converter(
            from: inputFormat,
            to: outputFormat,
            fileName: standardizedURL.lastPathComponent
        )

        return AudioDecodingContext(
            fileName: standardizedURL.lastPathComponent,
            audioFile: audioFile,
            inputFormat: inputFormat,
            outputFormat: outputFormat,
            converter: converter,
            inputFrameCapacity: computedInputFrameCapacity(
                inputFormat: inputFormat,
                sampleRate: sampleRate
            ),
            outputFrameCapacity: outputFrameCapacity,
            maxOutputFrames: computedMaxOutputFrames(
                maxDuration: maxDuration,
                sampleRate: sampleRate
            )
        )
    }

    // MARK: - Private helpers

    private nonisolated func validateSampleRate(_ sampleRate: Double) throws {
        guard sampleRate > 0 else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Audio decoding requires a positive target sample rate."
            )
        }
    }

    private nonisolated func openAudioFile(at url: URL) throws -> AVAudioFile {
        do {
            return try AVAudioFile(forReading: url)
        } catch {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Failed to open audio file '\(url.lastPathComponent)': \(error.localizedDescription)"
            )
        }
    }

    private nonisolated func computedInputFrameCapacity(
        inputFormat: AVAudioFormat,
        sampleRate: Double
    ) -> AVAudioFrameCount {
        let ratio     = max(inputFormat.sampleRate, 1) / sampleRate
        let estimated = ceil(Double(outputFrameCapacity) * ratio)
        return AVAudioFrameCount(max(Double(outputFrameCapacity), estimated))
    }

    private nonisolated func computedMaxOutputFrames( maxDuration: TimeInterval?, sampleRate: Double ) -> Int64 {
        guard let maxDuration else { return .max }
        return max(0, Int64(maxDuration * sampleRate))
    }
}
