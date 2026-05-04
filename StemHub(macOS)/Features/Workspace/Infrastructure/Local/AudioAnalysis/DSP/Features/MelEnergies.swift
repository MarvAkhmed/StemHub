//
//  MelEnergies.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A bag of per-band mel energy values ready for DCT transformation.
///
/// `MelEnergies` is a thin wrapper that makes the data-flow intent explicit:
/// these float values represent mel-band energies, not raw samples or spectra.
///
/// ## Sendable
/// All stored properties are value types; struct is unconditionally `Sendable`.
struct MelEnergies: Sendable {

    /// One energy value per mel band.
    let values: [Float]

    /// The number of mel bands. Must equal `values.count`.
    let bandCount: Int
}
