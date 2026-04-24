//
//  AudioPlayerViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioPlayerViewModel: NSObject, ObservableObject {
    @Published private(set) var currentURL: URL?
    @Published private(set) var isPlaying = false
    @Published private(set) var isPreparing = false
    @Published var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var playbackErrorMessage: String?
    @Published private(set) var playbackRate: Double

    private let playbackPreparer: AudioPlaybackPreparing
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var accessSession: SecurityScopedURLAccessSession?
    private static let progressInterval: TimeInterval = 0.25
    private static let progressTolerance: TimeInterval = 0.1
    private static let minimumProgressDelta: Double = 0.03

    init(
        playbackPreparer: AudioPlaybackPreparing,
        defaultPlaybackRate: Double
    ) {
        self.playbackPreparer = playbackPreparer
        self.playbackRate = defaultPlaybackRate
        super.init()
    }

    func load(url: URL) async {
        guard currentURL != url else { return }

        teardownPlayer()
        isPreparing = true
        playbackErrorMessage = nil

        do {
            let preparedPlayback = try await playbackPreparer.preparePlayback(for: url)
            currentURL = url
            accessSession = preparedPlayback.accessSession
            let player = try AVAudioPlayer(contentsOf: preparedPlayback.playbackURL)
            player.enableRate = true
            player.rate = Float(playbackRate)
            player.delegate = self
            player.prepareToPlay()
            self.player = player
            duration = player.duration.isFinite ? player.duration : preparedPlayback.duration
            currentTime = 0
            isPreparing = false
        } catch {
            currentURL = nil
            playbackErrorMessage = error.localizedDescription
            accessSession?.invalidate()
            accessSession = nil
            isPreparing = false
        }
    }

    func togglePlayback() {
        guard let player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
            stopProgressTimer()
        } else {
            let didStart = player.play()
            player.rate = Float(playbackRate)
            if didStart {
                isPlaying = true
                startProgressTimer()
            } else {
                playbackErrorMessage = "StemHub could not start audio playback for this file."
            }
        }
    }

    func stop() {
        guard let player else { return }
        player.pause()
        player.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopProgressTimer()
    }

    func seek(to time: Double) {
        guard let player else { return }

        let safeTime = max(0, min(time, duration))
        player.currentTime = safeTime
        currentTime = safeTime
    }

    func dispose() {
        teardownPlayer()
    }

    func updatePlaybackRate(_ value: Double) {
        playbackRate = value
        guard let player else { return }
        player.rate = Float(value)
        if isPlaying {
            _ = player.play()
            player.rate = Float(value)
        }
    }
}

private extension AudioPlayerViewModel {
    func startProgressTimer() {
        stopProgressTimer()
        let timer = Timer(
            timeInterval: Self.progressInterval,
            target: self,
            selector: #selector(handleProgressTimerTick),
            userInfo: nil,
            repeats: true
        )
        timer.tolerance = Self.progressTolerance
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    func teardownPlayer() {
        player?.pause()
        player = nil
        stopProgressTimer()
        accessSession?.invalidate()
        accessSession = nil
        isPlaying = false
        isPreparing = false
        currentTime = 0
        duration = 0
    }

    func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    @objc
    func handleProgressTimerTick() {
        guard let player else { return }
        let nextTime = player.currentTime
        guard abs(nextTime - currentTime) >= Self.minimumProgressDelta else { return }
        currentTime = nextTime
    }
}

extension AudioPlayerViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.currentTime = self.duration
            self.isPlaying = false
            self.stopProgressTimer()
        }
    }
}
