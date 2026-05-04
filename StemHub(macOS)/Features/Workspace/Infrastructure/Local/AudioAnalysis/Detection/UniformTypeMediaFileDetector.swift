//
//  UniformTypeMediaFileDetector.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation
import UniformTypeIdentifiers

/// Implements both `AudioFileProviding` and `MIDIFileProviding` using
/// `UniformTypeContentTypeResolver` to inspect UTI conformance.
///
/// LAW-D1: `UniformTypeContentTypeResolver` is a pure caseless-enum namespace
///   with no static stored state — calling its static method here is acceptable
///   and does not violate the no-singleton rule.
/// LAW-C1: struct — detection is stateless and deterministic.
/// LAW-N1: One primary type per file.
struct UniformTypeMediaFileDetector: AudioFileProviding, MIDIFileProviding {

    // MARK: - AudioFileProviding
    func isAudioFile(_ url: URL) -> Bool {
        guard let contentType = UniformTypeContentTypeResolver.contentType(for: url) else { return false }
        return contentType.conforms(to: .audio)
    }

    // MARK: - MIDIFileProviding
    func isMIDIFile(_ url: URL) -> Bool {
        guard let contentType = UniformTypeContentTypeResolver.contentType(for: url) else { return false }
        return contentType.conforms(to: .midi)
    }
}
