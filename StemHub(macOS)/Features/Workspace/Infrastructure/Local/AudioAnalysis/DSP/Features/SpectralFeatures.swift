//
//  SpectralFeatures.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Low-level spectral shape descriptors produced by `SpectralFeatureExtractor`.
///
/// ## Sendable
/// All stored properties are value types; struct is unconditionally `Sendable`.
struct SpectralFeatures: Sendable {

    /// Spectral centroid normalised to [0, 1].
    ///
    /// The centroid is the frequency-weighted mean of the magnitude spectrum,
    /// normalised by the total number of bins. A value near 0 indicates
    /// low-frequency dominance; a value near 1 indicates high-frequency dominance.
    let centroid: Float

    /// Spectral flux relative to the previous frame, or `nil` for the first frame.
    ///
    /// Spectral flux measures the sum of positive magnitude changes between the
    /// current and previous frames. High flux indicates a spectral onset.
    let flux: Float?
}
