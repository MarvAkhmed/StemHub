//
//  FFTSetupProviding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate

/// Provides a pre-computed vDSP FFT setup object.
///
/// LAW-D3: `Providing` suffix — approved.
/// LAW-C3: Marked `Sendable`.
protocol FFTSetupProviding: Sendable {
    var setup: FFTSetup { get }
    var log2Length: vDSP_Length { get }
}
