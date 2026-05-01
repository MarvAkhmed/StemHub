//
//  AudioPlaybackService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

@MainActor
protocol AudioPlaybackServicing: AnyObject {
    var updates: AsyncStream<AudioPlaybackState> { get }
    func load(url: URL, playbackRate: Double) async throws -> AudioPlaybackState
    func togglePlayback() throws -> AudioPlaybackState
    func stop() -> AudioPlaybackState
    func seek(to time: Double) -> AudioPlaybackState
    func updatePlaybackRate(_ value: Double) -> AudioPlaybackState
    func dispose()
}

@MainActor
final class AudioPlaybackService: AudioPlaybackServicing {
    private let controller: AudioPlaybackControlling

    init(controller: AudioPlaybackControlling) {
        self.controller = controller
    }

    var updates: AsyncStream<AudioPlaybackState> {
        controller.updates
    }

    func load(url: URL, playbackRate: Double) async throws -> AudioPlaybackState {
        try await controller.load(url: url, playbackRate: playbackRate)
    }

    func togglePlayback() throws -> AudioPlaybackState {
        try controller.togglePlayback()
    }

    func stop() -> AudioPlaybackState {
        controller.stop()
    }

    func seek(to time: Double) -> AudioPlaybackState {
        controller.seek(to: time)
    }

    func updatePlaybackRate(_ value: Double) -> AudioPlaybackState {
        controller.updatePlaybackRate(value)
    }

    func dispose() {
        controller.dispose()
    }
}

@MainActor
protocol AudioPlaybackServiceMaking {
    func makeAudioPlaybackService(defaultPlaybackRate: Double) -> AudioPlaybackServicing
}
