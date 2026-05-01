//
//  AudioAnalysisProtocols.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation
import UniformTypeIdentifiers

protocol AudioFileDetecting: Sendable {
    func isAudioFile(_ url: URL) -> Bool
}

protocol MIDIFileDetecting: Sendable {
    func isMIDIFile(_ url: URL) -> Bool
}

struct UniformTypeMediaFileDetector: AudioFileDetecting, MIDIFileDetecting {
    func isAudioFile(_ url: URL) -> Bool {
        guard let contentType = UniformTypeContentTypeResolver.contentType(for: url) else {
            return false
        }

        return contentType.conforms(to: .audio)
    }

    func isMIDIFile(_ url: URL) -> Bool {
        guard let contentType = UniformTypeContentTypeResolver.contentType(for: url) else {
            return false
        }

        return contentType.conforms(to: .midi)
    }
}


