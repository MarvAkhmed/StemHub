//
//  AVFoundationPCMHasher.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 01.05.2026.
//

import CryptoKit
import Foundation

protocol PCMHashing: Sendable {
    nonisolated func pcmHash(for url: URL) async throws -> String
}

struct AVFoundationPCMHasher: PCMHashing {
    private let targetSampleRate: Double

    init(targetSampleRate: Double = 22_050) {
        self.targetSampleRate = targetSampleRate
    }

    nonisolated func pcmHash(for url: URL) async throws -> String {
        let targetSampleRate = targetSampleRate

        return try await Task.detached(priority: .utility) {
            var hasher = SHA256()

            try AVFoundationAudioPCMDecoder.decodeMonoFloat32Samples(from: url,
                                                                     sampleRate: targetSampleRate) { samples in
                let quantizedSamples = samples.map(Self.quantizedSample)

                let data = quantizedSamples.withUnsafeBufferPointer { buffer in
                    Data(buffer: buffer)
                }

                hasher.update(data: data)
            }

            return Self.hexString(from: hasher.finalize())
        }.value
    }

    nonisolated private static func quantizedSample(_ sample: Float) -> Int16 {
        let clamped = max(-1, min(1, sample))
        return Int16((clamped * Float(Int16.max)).rounded()).littleEndian
    }

    nonisolated private static func hexString(from digest: SHA256.Digest) -> String {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}
