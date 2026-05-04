//
//  AudioPlaybackPreparing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import AVFoundation
import Foundation

struct PreparedAudioPlayback {
    let playbackURL: URL
    let duration: Double
    let accessSession: SecurityScopedURLAccessSession
}

protocol AudioPlaybackPreparing {
    func preparePlayback(for url: URL) async throws -> PreparedAudioPlayback
}

struct DefaultAudioPlaybackPreparer: AudioPlaybackPreparing {
    func preparePlayback(for url: URL) async throws -> PreparedAudioPlayback {
        let accessSession = DefaultSecurityScopedURLAccessSession(url: url)

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            accessSession.invalidate()
            throw AudioPlaybackPreparationError.unreadableFile
        }

        let asset = AVURLAsset(url: url)
        let isPlayable = try await asset.load(.isPlayable)

        guard isPlayable else {
            accessSession.invalidate()
            throw AudioPlaybackPreparationError.unsupportedFormat
        }

        let durationTime = try await asset.load(.duration)
        let duration = durationTime.seconds.isFinite ? durationTime.seconds : 0

        return PreparedAudioPlayback(
            playbackURL: url,
            duration: duration,
            accessSession: accessSession
        )
    }
}

