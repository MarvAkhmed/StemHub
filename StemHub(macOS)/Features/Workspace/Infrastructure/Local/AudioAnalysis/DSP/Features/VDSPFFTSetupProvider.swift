//
//  VDSPFFTSetupProvider.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate

/// Manages the lifetime of a `vDSP_create_fftsetup` object.
///
/// ## Why a class?
/// `FFTSetup` is a C pointer (`OpaquePointer`) allocated by `vDSP_create_fftsetup`
/// and freed by `vDSP_destroy_fftsetup`. Only a `class` type in Swift can
/// implement `deinit` to guarantee the pointer is freed exactly once.
/// This is the Objective-C/C bridging exception permitted by LAW-C1.
///
/// ## Thread safety
/// `setup` is written once in `init` and read-only thereafter.
/// `nonisolated(unsafe)` is the correct annotation for a C pointer stored in
/// a `Sendable` type (Swift 5.10+). No concurrent mutations occur.
final class VDSPFFTSetupProvider: FFTSetupProviding, Sendable {
    nonisolated(unsafe) public let setup: FFTSetup
    public let log2Length: vDSP_Length

    /// - Parameter log2Length: Base-2 logarithm of the FFT frame length
    ///   (e.g. 11 for a 2048-sample frame).
    /// - Throws: `AudioDSPError.fftSetupCreationFailed` when vDSP cannot
    ///   allocate the setup structure.
    public init(log2Length: vDSP_Length) throws {
        guard let createdSetup = vDSP_create_fftsetup(
            log2Length,
            FFTRadix(kFFTRadix2)
        ) else {
            throw AudioDSPError.fftSetupCreationFailed(log2Length: log2Length)
        }
        self.setup      = createdSetup
        self.log2Length = log2Length
    }

    deinit {
        vDSP_destroy_fftsetup(setup)
    }
}
