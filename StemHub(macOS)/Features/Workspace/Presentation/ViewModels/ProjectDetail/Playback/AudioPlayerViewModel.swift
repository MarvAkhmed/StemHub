//
//  AudioPlayerViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Combine
import Foundation

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    @Published private(set) var currentURL: URL?
    @Published private(set) var isPlaying = false
    @Published private(set) var isPreparing = false
    @Published var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var playbackErrorMessage: String?
    @Published private(set) var playbackRate: Double

    private let playbackService: AudioPlaybackServicing
    private var updatesTask: Task<Void, Never>?

    init(
        playbackService: AudioPlaybackServicing,
        defaultPlaybackRate: Double
    ) {
        self.playbackService = playbackService
        self.playbackRate = defaultPlaybackRate
        bindPlaybackUpdates()
    }

    func load(url: URL) async {
        guard currentURL != url else { return }

        playbackErrorMessage = nil
        apply(.idle(playbackRate: playbackRate))
        isPreparing = true

        do {
            let state = try await playbackService.load(url: url, playbackRate: playbackRate)
            apply(state)
        } catch {
            playbackErrorMessage = error.localizedDescription
            isPreparing = false
        }
    }

    func togglePlayback() {
        do {
            apply(try playbackService.togglePlayback())
        } catch {
            playbackErrorMessage = error.localizedDescription
        }
    }

    func stop() {
        apply(playbackService.stop())
    }

    func seek(to time: Double) {
        apply(playbackService.seek(to: time))
    }

    func dispose() {
        updatesTask?.cancel()
        updatesTask = nil
        playbackService.dispose()
    }

    func updatePlaybackRate(_ value: Double) {
        apply(playbackService.updatePlaybackRate(value))
    }
}

private extension AudioPlayerViewModel {
    func bindPlaybackUpdates() {
        updatesTask = Task { [weak self] in
            guard let self else { return }

            for await state in playbackService.updates {
                apply(state)
            }
        }
    }

    func apply(_ state: AudioPlaybackState) {
        currentURL = state.currentURL
        isPlaying = state.isPlaying
        isPreparing = state.isPreparing
        currentTime = state.currentTime
        duration = state.duration
        playbackRate = state.playbackRate
        playbackErrorMessage = state.errorMessage
    }
}
