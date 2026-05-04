//
//  MIDIFileProviding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Tests whether a URL refers to a MIDI file.
///
/// Renamed from `MIDIFileDetecting` → `MIDIFileProviding` (LAW-D3).
/// LAW-C3: Marked `Sendable`.
/// LAW-N1: One protocol per file.
protocol MIDIFileProviding: Sendable {
    /// Returns `true` if the URL at `url` refers to a MIDI file.
    ///
    /// - Parameter url: The URL to test.
    func isMIDIFile(_ url: URL) -> Bool
}
