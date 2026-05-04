//
//  DefaultAudioSampleExtractor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioSampleProviding`.
struct DefaultAudioSampleExtractor: AudioSampleProviding {
    nonisolated func samples(from buffer: AVAudioPCMBuffer,
                             emittedFrames: Int64, maxOutputFrames: Int64,
                             fileName: String) throws -> [Float] {
        let frameCount = computeFrameCount(
            from: buffer,
            emittedFrames: emittedFrames,
            maxOutputFrames: maxOutputFrames
        )
        guard frameCount > 0 else { return [] }
        return try extractSamples(from: buffer, frameCount: frameCount, fileName: fileName)
    }
    
    // MARK: - Private helpers
    
    private nonisolated func computeFrameCount(from buffer: AVAudioPCMBuffer,
                                               emittedFrames: Int64, maxOutputFrames: Int64 ) -> Int {
        let availableFrames = Int(buffer.frameLength)
        let remainingFrames = max(0, maxOutputFrames - emittedFrames)
        return min(availableFrames, Int(remainingFrames))
    }
    
    private nonisolated func extractSamples( from buffer: AVAudioPCMBuffer,
                                             frameCount: Int, fileName: String
    ) throws -> [Float] {
        guard let channelData = buffer.floatChannelData?.pointee else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "Decoded audio channel data was unavailable for '\(fileName)'."
            )
        }
        return Array(UnsafeBufferPointer(start: channelData, count: frameCount))
    }
}
