//
//  BasicFeatureExtractor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Stateful feature accumulator used by the basic fingerprinting pipeline.
///
/// ## Isolation
/// This struct is explicitly NOT isolated to any actor. Every method is
/// `nonisolated` (the default for structs). The struct is created and mutated
/// exclusively inside a single `Task` in `BasicAudioFingerprinter` — no
/// concurrent access is possible, no actor or lock is required.
///
/// ## Feature vector layout (6 features per frame)
/// | Index | Feature              | Description                        |
/// |-------|----------------------|------------------------------------|
/// | 0     | RMS energy           | `sqrt(mean(x²))`                   |
/// | 1     | Mean absolute value  | `mean(|x|)`                        |
/// | 2     | Zero-crossing rate   | Sign-change count / (N − 1)        |
/// | 3     | First-difference energy | `mean(|xₙ − xₙ₋₁|)`            |
/// | 4     | Crest factor         | `peak / max(RMS, ε)`               |
/// | 5     | Onset strength       | `max(0, RMS − previousRMS)`        |
nonisolated struct BasicFeatureExtractor: AudioFeatureProcessing {

    // MARK: - Configuration (immutable after init)

    private let frameSize:    Int
    private let hopSize:      Int
    private let segmentCount: Int

    // MARK: - Mutable accumulation state

    private var sampleBuffer:    [Float]   = []
    private var frameStartIndex: Int       = 0
    private var frameFeatures:   [[Float]] = []
    private var previousRMS:     Float     = 0

    // MARK: - Init

    /// Creates a feature extractor for the given analysis parameters.
    ///
    /// Explicitly no isolation annotation — callable from any context.
    init(frameSize: Int, hopSize: Int, segmentCount: Int) {
        self.frameSize    = frameSize
        self.hopSize      = hopSize
        self.segmentCount = segmentCount
    }

    // MARK: - AudioFeatureProcessing

    mutating func consume(_ samples: [Float]) {
        sampleBuffer.append(contentsOf: samples)

        while sampleBuffer.count - frameStartIndex >= frameSize {
            let start = frameStartIndex
            let end   = start + frameSize
            let frame = Array(sampleBuffer[start..<end])
            frameFeatures.append(computeFeatures(for: frame))
            frameStartIndex += hopSize

            // Compact the buffer periodically to avoid unbounded growth.
            if frameStartIndex >= frameSize * 4 {
                sampleBuffer.removeFirst(frameStartIndex)
                frameStartIndex = 0
            }
        }
    }

    mutating func makeFingerprint(fileName: String) throws -> BasicAudioFingerprint {
        processRemainingTail()

        guard !frameFeatures.isEmpty else {
            throw AudioAnalysisImplementationError.decodeFailed(
                "No decodable audio samples were available for '\(fileName)'."
            )
        }

        let aggregated = aggregateIntoSegments(frameFeatures)
        let normalized = normalize(aggregated)

        guard !normalized.isEmpty else {
            throw AudioAnalysisImplementationError.invalidFingerprint(
                "Failed to build an audio fingerprint for '\(fileName)'."
            )
        }

        let featuresPerSegment = frameFeatures.isEmpty
            ? 0
            : aggregated.count / max(segmentCount, 1)

        return BasicAudioFingerprint(
            segmentCount:       segmentCount,
            featuresPerSegment: featuresPerSegment,
            featureVector:      normalized
        )
    }

    // MARK: - Private helpers

    private mutating func processRemainingTail() {
        let remaining = sampleBuffer.count - frameStartIndex
        guard remaining > 0 else { return }

        var tail = Array(sampleBuffer[frameStartIndex...])
        if tail.count < frameSize {
            tail.append(contentsOf: repeatElement(0, count: frameSize - tail.count))
        }
        frameFeatures.append(computeFeatures(for: Array(tail.prefix(frameSize))))
    }

    private mutating func computeFeatures(for frame: [Float]) -> [Float] {
        let rms   = rootMeanSquare(frame)
        let peak  = frame.reduce(0) { max($0, abs($1)) }
        let mav   = frame.reduce(0) { $0 + abs($1) } / Float(frame.count)
        let zcr   = Float(zeroCrossings(in: frame)) / Float(max(frame.count - 1, 1))
        let diffE = firstDifferenceEnergy(frame)
        let onset = max(0, rms - previousRMS)
        previousRMS = rms

        return [rms, mav, zcr, diffE, peak / max(rms, 0.000_1), onset]
    }

    private func aggregateIntoSegments(_ features: [[Float]]) -> [Float] {
        guard !features.isEmpty else { return [] }

        let featureCount = features[0].count
        var aggregated   = [Float](
            repeating: 0,
            count: segmentCount * featureCount
        )

        for segIdx in 0..<segmentCount {
            let lo = min(
                features.count - 1,
                Int(
                    Double(segIdx) * Double(features.count)
                    / Double(segmentCount)
                )
            )
            let hi = min(
                features.count,
                max(
                    lo + 1,
                    Int(ceil(
                        Double(segIdx + 1) * Double(features.count)
                        / Double(segmentCount)
                    ))
                )
            )

            let slice = features[lo..<hi]
            guard !slice.isEmpty else { continue }

            for featIdx in 0..<featureCount {
                aggregated[segIdx * featureCount + featIdx] =
                    slice.reduce(0) { $0 + $1[featIdx] }
                    / Float(slice.count)
            }
        }
        return aggregated
    }

    private func normalize(_ values: [Float]) -> [Float] {
        let mag = sqrt(values.reduce(0) { $0 + $1 * $1 })
        guard mag > 0 else { return values }
        return values.map { $0 / mag }
    }

    private func rootMeanSquare(_ frame: [Float]) -> Float {
        sqrt(frame.reduce(0) { $0 + $1 * $1 } / Float(frame.count))
    }

    private func zeroCrossings(in frame: [Float]) -> Int {
        guard frame.count > 1 else { return 0 }
        var count = 0
        var prev  = frame[0]
        for sample in frame.dropFirst() {
            if (prev >= 0 && sample < 0) || (prev < 0 && sample >= 0) {
                count += 1
            }
            prev = sample
        }
        return count
    }

    private func firstDifferenceEnergy(_ frame: [Float]) -> Float {
        guard frame.count > 1 else { return 0 }
        var total = Float.zero
        var prev  = frame[0]
        for sample in frame.dropFirst() {
            total += abs(sample - prev)
            prev   = sample
        }
        return total / Float(frame.count - 1)
    }
}
