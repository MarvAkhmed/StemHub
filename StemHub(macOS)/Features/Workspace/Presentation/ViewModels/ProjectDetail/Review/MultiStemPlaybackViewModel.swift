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

    private var players: [URL: AVAudioPlayer] = [:]
    private var securityScopedURLs: Set<URL> = []

    init(defaultPlaybackRate: Double) {
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
        do {
            if isPlaying(url) {
                stop(url)
            } else {
                try play(url, restart: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func playSelected() {
        do {
            stopAll()
            for url in selectedURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                try play(url, restart: true)
            }
        } catch {
            errorMessage = error.localizedDescription
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
        for url in securityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        securityScopedURLs.removeAll()
    }
}

private extension MultiStemPlaybackViewModel {
    func play(_ url: URL, restart: Bool) throws {
        let player = try player(for: url)
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

    func player(for url: URL) throws -> AVAudioPlayer {
        if let player = players[url] {
            player.enableRate = true
            player.rate = Float(playbackRate)
            return player
        }

        beginAccessing(url)
        let player = try AVAudioPlayer(contentsOf: url)
        player.enableRate = true
        player.rate = Float(playbackRate)
        player.delegate = self
        player.prepareToPlay()
        players[url] = player
        return player
    }

    func beginAccessing(_ url: URL) {
        guard !securityScopedURLs.contains(url) else { return }
        if url.startAccessingSecurityScopedResource() {
            securityScopedURLs.insert(url)
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
