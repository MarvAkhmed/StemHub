//
//  AVFoundationAudioPCMDecoder.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

enum AVFoundationAudioPCMDecoder {
    private static let outputChunkFrameCapacity: AVAudioFrameCount = 4_096

    nonisolated static func decodeMonoFloat32Samples(from url: URL, sampleRate: Double,
                                                     maxDuration: TimeInterval? = nil,
                                                     processChunk: ([Float]) throws -> Void) throws {
        guard sampleRate > 0 else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Audio decoding requires a positive target sample rate."
            )
        }

        let audioFile = try AVAudioFile(forReading: url)
        let inputFormat = audioFile.processingFormat

        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                               sampleRate: sampleRate,
                                               channels: 1,
                                               interleaved: false)
        else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Failed to create a mono PCM format for \(url.lastPathComponent)."
            )
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Failed to create an audio converter for \(url.lastPathComponent)."
            )
        }
        let capacity =  Self.outputChunkFrameCapacity
                   
        let y = Int(ceil(Double(capacity) * max(inputFormat.sampleRate, 1) / sampleRate ))
        let frameCount = max(Int(capacity), y)
        let inputFrameCapacity = AVAudioFrameCount(frameCount)

        let maxOutputFrames = maxDuration.map { Int64($0 * sampleRate) }
        var emittedFrames: Int64 = 0
        var reachedEndOfStream = false
        var capturedReadError: Error?

        decodeLoop: while true {
            try Task.checkCancellation()

            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: capacity
            ) else {
                throw AudioAnalysisImplementationError.decodeFailed(
                    "Failed to allocate an output PCM buffer for \(url.lastPathComponent)."
                )
            }

            var conversionError: NSError?
            let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
                if let capturedReadError {
                    outStatus.pointee = .noDataNow
                    _ = capturedReadError
                    return nil
                }

                if reachedEndOfStream {
                    outStatus.pointee = .endOfStream
                    return nil
                }

                guard let inputBuffer = AVAudioPCMBuffer(
                    pcmFormat: inputFormat,
                    frameCapacity: inputFrameCapacity
                ) else {
                    outStatus.pointee = .noDataNow
                    return nil
                }

                do {
                    try audioFile.read(into: inputBuffer, frameCount: inputFrameCapacity)
                } catch {
                    capturedReadError = error
                    outStatus.pointee = .noDataNow
                    return nil
                }

                if inputBuffer.frameLength == 0 {
                    reachedEndOfStream = true
                    outStatus.pointee = .endOfStream
                    return nil
                }

                outStatus.pointee = .haveData
                return inputBuffer
            }

            if let capturedReadError {
                throw capturedReadError
            }

            if let conversionError {
                throw conversionError
            }

            if outputBuffer.frameLength > 0 {
                guard let channelData = outputBuffer.floatChannelData?.pointee else {
                    throw AudioAnalysisImplementationError.decodeFailed(
                        "Decoded audio channel data was unavailable for \(url.lastPathComponent)."
                    )
                }

                var frameCount = Int(outputBuffer.frameLength)
                if let maxOutputFrames {
                    let remainingFrames = max(0, maxOutputFrames - emittedFrames)
                    if remainingFrames == 0 {
                        break decodeLoop
                    }
                    frameCount = min(frameCount, Int(remainingFrames))
                }

                let samples = Array(
                    UnsafeBufferPointer(
                        start: channelData,
                        count: frameCount
                    )
                )

                if !samples.isEmpty {
                    try processChunk(samples)
                    emittedFrames += Int64(samples.count)
                }
            }

            if let maxOutputFrames, emittedFrames >= maxOutputFrames {
                break
            }

            switch status {
            case .haveData, .inputRanDry:
                continue

            case .endOfStream:
                break decodeLoop

            case .error:
                throw AudioAnalysisImplementationError.decodeFailed(
                    "Audio conversion failed for \(url.lastPathComponent)."
                )

            @unknown default:
                throw AudioAnalysisImplementationError.decodeFailed(
                    "Audio conversion returned an unknown status for \(url.lastPathComponent)."
                )
            }
        }
    }
}
