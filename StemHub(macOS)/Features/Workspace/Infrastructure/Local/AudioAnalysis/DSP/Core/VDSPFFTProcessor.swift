//
//  VDSPFFTProcessor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate
import Foundation

/// Computes magnitude spectra using the vDSP real FFT.
///
/// LAW-C1: Converted from `final class` to `struct`.
///   - `VDSPFFTSetupProvider` owns the `FFTSetup` C pointer and its `deinit`.
///   - `VDSPFFTProcessor` only holds an immutable reference to the provider.
///   - No `deinit` is required here, so a struct is correct.
/// LAW-C7: `Sendable` conformance is safe — all stored properties are `Sendable`:
///   - `setupProvider: any FFTSetupProviding` — the protocol requires `Sendable`.
///   - `windowFunction: WindowFunction` — enum, unconditionally `Sendable`.
///   - `sampleRate: Double` — value type, `Sendable`.
struct VDSPFFTProcessor: FFTProcessing, Sendable {

    // MARK: - Dependencies

    private let setupProvider: any FFTSetupProviding
    private let windowFunction: WindowFunction
    private let sampleRate: Double

    // MARK: - Init

    public init(
        setupProvider: any FFTSetupProviding,
        windowFunction: WindowFunction,
        sampleRate: Double
    ) throws {
        guard sampleRate > DSPConstants.zeroDouble else {
            throw AudioDSPError.invalidSampleRate(sampleRate)
        }
        self.setupProvider  = setupProvider
        self.windowFunction = windowFunction
        self.sampleRate     = sampleRate
    }

    // MARK: - FFTProcessing

    public func magnitudeSpectrum(for frame: DSPFrame) throws -> MagnitudeSpectrum {
        guard frame.log2Length == setupProvider.log2Length else {
            throw AudioDSPError.fftSetupLengthMismatch(
                expected: frame.log2Length,
                actual: setupProvider.log2Length
            )
        }

        let windowedSamples = windowFunction.apply(to: frame)
        let halfLength      = frame.length / DSPConstants.nyquistDivisor
        let binCount        = halfLength + DSPConstants.firstNonDCBin

        var realParts      = [Float](repeating: DSPConstants.zeroFloat, count: halfLength)
        var imaginaryParts = [Float](repeating: DSPConstants.zeroFloat, count: halfLength)

        try realParts.withUnsafeMutableBufferPointer { realBuf in
            try imaginaryParts.withUnsafeMutableBufferPointer { imagBuf in
                guard
                    let realBase = realBuf.baseAddress,
                    let imagBase = imagBuf.baseAddress
                else { throw AudioDSPError.unsafeBufferAccessFailed }

                var splitComplex = DSPSplitComplex(realp: realBase, imagp: imagBase)

                try windowedSamples.withUnsafeBytes { rawBuf in
                    let complexBuf = rawBuf.bindMemory(to: DSPComplex.self)
                    guard let complexBase = complexBuf.baseAddress else {
                        throw AudioDSPError.unsafeBufferAccessFailed
                    }
                    vDSP_ctoz(
                        complexBase, 2,
                        &splitComplex, 1,
                        vDSP_Length(halfLength)
                    )
                    vDSP_fft_zrip(
                        setupProvider.setup,
                        &splitComplex, 1,
                        frame.log2Length,
                        FFTDirection(FFT_FORWARD)
                    )
                }
            }
        }

        var magnitudes = [Float](repeating: DSPConstants.zeroFloat, count: binCount)
        magnitudes[0]          = abs(realParts[0])
        magnitudes[halfLength] = abs(imaginaryParts[0])

        if halfLength > DSPConstants.firstNonDCBin {
            for bin in DSPConstants.firstNonDCBin..<halfLength {
                let r = realParts[bin]
                let i = imaginaryParts[bin]
                magnitudes[bin] = sqrt(r * r + i * i)
            }
        }

        var scale = DSPConstants.fftScaleNumerator / Float(frame.length)
        vDSP_vsmul(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(binCount))

        return MagnitudeSpectrum(
            magnitudes: magnitudes,
            binCount: binCount,
            sampleRate: sampleRate
        )
    }
}
