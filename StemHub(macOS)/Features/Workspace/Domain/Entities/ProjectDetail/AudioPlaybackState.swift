//
//  AudioPlaybackState.swift
//  StemHub(macOS)
//
// Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct AudioPlaybackState: Sendable {
    let currentURL: URL?
    let isPlaying: Bool
    let isPreparing: Bool
    let currentTime: Double
    let duration: Double
    let playbackRate: Double
    let errorMessage: String?

    static func idle(playbackRate: Double) -> AudioPlaybackState {
        AudioPlaybackState(
            currentURL: nil,
            isPlaying: false,
            isPreparing: false,
            currentTime: 0,
            duration: 0,
            playbackRate: playbackRate,
            errorMessage: nil
        )
    }
}
