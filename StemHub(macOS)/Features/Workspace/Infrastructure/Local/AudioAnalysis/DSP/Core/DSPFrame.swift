//
//  DSPFrame.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate
import Foundation

/// A validated, fixed-length window of mono float32 PCM samples ready for DSP.
///
/// `DSPFrame` is constructed only through its throwing `init(samples:)`.
/// The initialiser validates that the sample count is a positive power of two,
/// which is the precondition required by all vDSP FFT functions.
///
/// ## Why a struct?
/// - Pure value semantics: a frame is a snapshot of samples, not a mutable entity.
/// - `Sendable`: `[Float]` and `Int` / `vDSP_Length` are unconditionally `Sendable`.
/// - No `deinit` required: no heap resources to free beyond the `[Float]` array.
struct DSPFrame: Sendable {

    // MARK: - Stored properties

    /// The windowed sample data for this frame.
    let samples: [Float]

    /// The number of samples in this frame. Always a positive power of two.
    let length: Int

    /// Base-2 logarithm of `length`. Pre-computed to avoid repeated `log2` calls
    /// inside hot vDSP paths.
    let log2Length: vDSP_Length

    // MARK: - Init

    /// Creates a validated `DSPFrame` from a sample array.
    ///
    /// - Parameter samples: The PCM sample array. Must have a count that is a
    ///   positive power of two (e.g. 512, 1024, 2048, 4096).
    /// - Throws: `AudioDSPError.invalidSpectrumLength` when `samples.count` is
    ///   not a positive power of two.
    init(samples: [Float]) throws {
        let length = samples.count
        guard length > 0, (length & (length - 1)) == 0 else {
            throw AudioDSPError.invalidSpectrumLength(length)
        }
        self.samples    = samples
        self.length     = length
        self.log2Length = vDSP_Length(log2(Double(length)))
    }
}
