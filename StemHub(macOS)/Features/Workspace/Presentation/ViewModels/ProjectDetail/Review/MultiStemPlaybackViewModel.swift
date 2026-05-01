//
//  MultiStemPlaybackViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class MultiStemPlaybackViewModel: NSObject, ObservableObject {
    @Published private(set) var selectedURLs: Set<URL> = []
    @Published private(set) var playingURLs: Set<URL> = []
    @Published var playbackRate: Double
    @Published var errorMessage: String?

    private let playbackPreparer: AudioPlaybackPreparing
    private var players: [URL: AVAudioPlayer] = [:]
    private var accessSessions: [URL: SecurityScopedURLAccessSession] = [:]

    init(
        playbackPreparer: AudioPlaybackPreparing,
        defaultPlaybackRate: Double
    ) {
        self.playbackPreparer = playbackPreparer
        playbackRate = defaultPlaybackRate
        super.init()
    }

    func toggleSelection(for url: URL) {
        if selectedURLs.contains(url) {
            selectedURLs.remove(url)
        } else {
            selectedURLs.insert(url)
        }
    }

    func isSelected(_ url: URL) -> Bool {
        selectedURLs.contains(url)
    }

    func isPlaying(_ url: URL) -> Bool {
        playingURLs.contains(url)
    }

    func togglePlayback(for url: URL) {
        if isPlaying(url) {
            stop(url)
        } else {
            Task {
                await playHandlingError(url, restart: true)
            }
        }
    }

    func playSelected() {
        Task {
            await playSelectedHandlingError()
        }
    }

    func stopAll() {
        for player in players.values {
            player.stop()
            player.currentTime = 0
        }
        playingURLs.removeAll()
    }

    func updatePlaybackRate(_ value: Double) {
        playbackRate = value
        for player in players.values {
            player.enableRate = true
            player.rate = Float(value)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func dispose() {
        stopAll()
        players.removeAll()
        selectedURLs.removeAll()
        for accessSession in accessSessions.values {
            accessSession.invalidate()
        }
        accessSessions.removeAll()
    }
}

private extension MultiStemPlaybackViewModel {
    func playSelectedHandlingError() async {
        do {
            stopAll()
            for url in selectedURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                try await play(url, restart: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func playHandlingError(_ url: URL, restart: Bool) async {
        do {
            try await play(url, restart: restart)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func play(_ url: URL, restart: Bool) async throws {
        let player = try await player(for: url)
        if restart {
            player.currentTime = 0
        }
        let didStart = player.play()
        player.rate = Float(playbackRate)
        if didStart {
            playingURLs.insert(url)
        } else {
            throw NSError(
                domain: "StemHub.MultiStemPlayback",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "StemHub could not start playback for \(url.lastPathComponent)."]
            )
        }
    }

    func stop(_ url: URL) {
        guard let player = players[url] else { return }
        player.stop()
        player.currentTime = 0
        playingURLs.remove(url)
    }

    func player(for url: URL) async throws -> AVAudioPlayer {
        if let player = players[url] {
            player.enableRate = true
            player.rate = Float(playbackRate)
            return player
        }

        let preparedPlayback = try await playbackPreparer.preparePlayback(for: url)

        do {
            let player = try AVAudioPlayer(contentsOf: preparedPlayback.playbackURL)
            player.enableRate = true
            player.rate = Float(playbackRate)
            player.delegate = self
            player.prepareToPlay()
            players[url] = player
            accessSessions[url] = preparedPlayback.accessSession
            return player
        } catch {
            preparedPlayback.accessSession.invalidate()
            throw error
        }
    }
}

extension MultiStemPlaybackViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if let matchingURL = self.players.first(where: { $0.value === player })?.key {
                self.playingURLs.remove(matchingURL)
            }
        }
    }
}
