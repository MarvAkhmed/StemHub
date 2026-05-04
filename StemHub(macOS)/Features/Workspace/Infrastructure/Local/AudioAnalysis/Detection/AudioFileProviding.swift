//
//  AudioFileProviding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Tests whether a URL refers to an audio file.
///
/// Renamed from `AudioFileDetecting` → `AudioFileProviding` (LAW-D3).
/// LAW-C3: Marked `Sendable`.
/// LAW-N1: One protocol per file — `MIDIFileProviding` is in its own file.
protocol AudioFileProviding: Sendable {
    /// Returns `true` if the URL at `url` refers to an audio file.
    ///
    /// - Parameter url: The URL to test.
    func isAudioFile(_ url: URL) -> Bool
}
