//
//  FingerprintConfigError.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

import Foundation
import Accelerate

// MARK: - Configuration Errors

enum FingerprintConfigError: Error, LocalizedError {
    case invalidFrameSize(Int)
    case fftSetupFailed

    var errorDescription: String? {
        switch self {
        case .invalidFrameSize(let size):
            return "frameSize must be a power of two; received \(size)"
        case .fftSetupFailed:
            return "vDSP_create_fftsetup returned nil — check frameSize"
        }
    }
}
