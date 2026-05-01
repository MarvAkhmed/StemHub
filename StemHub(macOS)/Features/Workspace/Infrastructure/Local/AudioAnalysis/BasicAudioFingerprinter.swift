//
//  BasicAudioFingerprinter.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 01.05.2026.
//

import Foundation

protocol AudioFingerprinting: Sendable {
    associatedtype Fingerprint: Sendable
    nonisolated func fingerprint(for url: URL) async throws -> Fingerprint
}

struct BasicAudioFingerprint: Sendable, Equatable {
    let segmentCount: Int
    let featuresPerSegment: Int
    let featureVector: [Float]
}

struct BasicAudioFingerprinter: AudioFingerprinting {
    typealias Fingerprint = BasicAudioFingerprint

    private let targetSampleRate: Double
    private let maxDuration: TimeInterval
    private let frameSize: Int
    private let hopSize: Int
    private let segmentCount: Int

    init(
        targetSampleRate: Double = 11_025,
        maxDuration: TimeInterval = 180,
        frameSize: Int = 2_048,
        hopSize: Int = 1_024,
        segmentCount: Int = 32
    ) {
        self.targetSampleRate = targetSampleRate
        self.maxDuration = maxDuration
        self.frameSize = frameSize
        self.hopSize = hopSize
        self.segmentCount = segmentCount
    }

    nonisolated func fingerprint(for url: URL) async throws -> BasicAudioFingerprint {
        let targetSampleRate = targetSampleRate
        let maxDuration = maxDuration
        let frameSize = frameSize
        let hopSize = hopSize
        let segmentCount = segmentCount

        return try await Task.detached(priority: .utility) {
            var extractor = FeatureExtractor(
                frameSize: frameSize,
                hopSize: hopSize,
                segmentCount: segmentCount
            )

            try AVFoundationAudioPCMDecoder.decodeMonoFloat32Samples(
                from: url,
                sampleRate: targetSampleRate,
                maxDuration: maxDuration
            ) { samples in
                try Task.checkCancellation()
                extractor.consume(samples)
            }

            return try extractor.makeFingerprint(fileName: url.lastPathComponent)
        }.value
    }
}

private extension BasicAudioFingerprinter {
    struct FeatureExtractor {
        private let frameSize: Int
        private let hopSize: Int
        private let segmentCount: Int

        private var sampleBuffer: [Float] = []
        private var frameStartIndex = 0
        private var frameFeatures: [[Float]] = []
        private var previousRMS: Float = 0

        nonisolated init(
            frameSize: Int,
            hopSize: Int,
            segmentCount: Int
        ) {
            self.frameSize = frameSize
            self.hopSize = hopSize
            self.segmentCount = segmentCount
        }

        nonisolated mutating func consume(_ samples: [Float]) {
            sampleBuffer.append(contentsOf: samples)

            while sampleBuffer.count - frameStartIndex >= frameSize {
                let frame = Array(sampleBuffer[frameStartIndex..<(frameStartIndex + frameSize)])
                frameFeatures.append(computeFeatures(for: frame))
                frameStartIndex += hopSize

                if frameStartIndex >= frameSize * 4 {
                    sampleBuffer.removeFirst(frameStartIndex)
                    frameStartIndex = 0
                }
            }
        }

        nonisolated mutating func makeFingerprint(fileName: String) throws -> BasicAudioFingerprint {
            if frameFeatures.isEmpty, sampleBuffer.count > frameStartIndex {
                var remainingFrame = Array(sampleBuffer[frameStartIndex...])
                if remainingFrame.count < frameSize {
                    remainingFrame.append(
                        contentsOf: repeatElement(0, count: frameSize - remainingFrame.count)
                    )
                }
                frameFeatures.append(computeFeatures(for: Array(remainingFrame.prefix(frameSize))))
            }

            guard !frameFeatures.isEmpty else {
                throw AudioAnalysisImplementationError.decodeFailed(
                    "No decodable audio samples were available for \(fileName)."
                )
            }

            let aggregatedFeatures = aggregateIntoSegments(frameFeatures)
            let normalizedFeatures = normalize(aggregatedFeatures)

            guard !normalizedFeatures.isEmpty else {
                throw AudioAnalysisImplementationError.invalidFingerprint(
                    "Failed to build an audio fingerprint for \(fileName)."
                )
            }

            return BasicAudioFingerprint(
                segmentCount: segmentCount,
                featuresPerSegment: aggregatedFeatures.count / max(segmentCount, 1),
                featureVector: normalizedFeatures
            )
        }

        nonisolated private mutating func computeFeatures(for frame: [Float]) -> [Float] {
            let rms = rootMeanSquare(frame)
            let peak = frame.reduce(Float.zero) { partialResult, sample in
                max(partialResult, abs(sample))
            }
            let meanAbsoluteValue = frame.reduce(Float.zero) { partialResult, sample in
                partialResult + abs(sample)
            } / Float(max(frame.count, 1))
            let zeroCrossingRate = Float(zeroCrossings(in: frame)) / Float(max(frame.count - 1, 1))
            let differentialEnergy = firstDifferenceEnergy(frame)
            let onsetStrength = max(0, rms - previousRMS)
            previousRMS = rms

            return [
                rms,
                meanAbsoluteValue,
                zeroCrossingRate,
                differentialEnergy,
                peak / max(rms, 0.000_1),
                onsetStrength
            ]
        }

        nonisolated private func aggregateIntoSegments(_ frameFeatures: [[Float]]) -> [Float] {
            let featureCount = frameFeatures[0].count
            var aggregated = [Float](repeating: 0, count: segmentCount * featureCount)

            for segmentIndex in 0..<segmentCount {
                let lowerBound = min(
                    frameFeatures.count - 1,
                    Int(Double(segmentIndex) * Double(frameFeatures.count) / Double(segmentCount))
                )
                let upperBound = min(
                    frameFeatures.count,
                    max(
                        lowerBound + 1,
                        Int(
                            ceil(
                                Double(segmentIndex + 1) *
                                Double(frameFeatures.count) /
                                Double(segmentCount)
                            )
                        )
                    )
                )

                let segmentSlice = frameFeatures[lowerBound..<upperBound]
                for featureIndex in 0..<featureCount {
                    let value = segmentSlice.reduce(Float.zero) { partialResult, featureSet in
                        partialResult + featureSet[featureIndex]
                    } / Float(segmentSlice.count)
                    aggregated[(segmentIndex * featureCount) + featureIndex] = value
                }
            }

            return aggregated
        }

        nonisolated private func normalize(_ values: [Float]) -> [Float] {
            let magnitude = sqrt(values.reduce(Float.zero) { partialResult, value in
                partialResult + (value * value)
            })

            guard magnitude > 0 else {
                return values
            }

            return values.map { $0 / magnitude }
        }

        nonisolated private func rootMeanSquare(_ frame: [Float]) -> Float {
            sqrt(
                frame.reduce(Float.zero) { partialResult, sample in
                    partialResult + (sample * sample)
                } / Float(max(frame.count, 1))
            )
        }

        nonisolated private func zeroCrossings(in frame: [Float]) -> Int {
            guard frame.count > 1 else { return 0 }

            var crossings = 0
            var previousSample = frame[0]

            for sample in frame.dropFirst() {
                if (previousSample >= 0 && sample < 0) || (previousSample < 0 && sample >= 0) {
                    crossings += 1
                }
                previousSample = sample
            }

            return crossings
        }

        nonisolated private func firstDifferenceEnergy(_ frame: [Float]) -> Float {
            guard frame.count > 1 else { return 0 }

            var total: Float = 0
            var previousSample = frame[0]

            for sample in frame.dropFirst() {
                total += abs(sample - previousSample)
                previousSample = sample
            }

            return total / Float(frame.count - 1)
        }
    }
}
