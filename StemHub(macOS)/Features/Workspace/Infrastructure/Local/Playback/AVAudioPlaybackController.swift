//
//  AVAudioPlaybackController.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

protocol AudioPlaybackControlling: AnyObject {
    @MainActor var updates: AsyncStream<AudioPlaybackState> { get }

    @MainActor
    func load(url: URL, playbackRate: Double) async throws -> AudioPlaybackState

    @MainActor
    func togglePlayback() throws -> AudioPlaybackState

    @MainActor
    func stop() -> AudioPlaybackState

    @MainActor
    func seek(to time: Double) -> AudioPlaybackState

    @MainActor
    func updatePlaybackRate(_ value: Double) -> AudioPlaybackState

    @MainActor
    func dispose()
}

@MainActor
final class AVAudioPlaybackController: NSObject, AudioPlaybackControlling {
    private let playbackPreparer: AudioPlaybackPreparing
    private var player: AVAudioPlayer?
    private var currentURL: URL?
    private var isPreparing = false
    private var playbackRate: Double
    private var progressTimer: Timer?
    private var accessSession: SecurityScopedURLAccessSession?
    private var continuation: AsyncStream<AudioPlaybackState>.Continuation?

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

    var updates: AsyncStream<AudioPlaybackState> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.makeState())
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuation = nil
                }
            }
        }
    }

    func load(url: URL, playbackRate: Double) async throws -> AudioPlaybackState {
        guard currentURL != url else {
            return makeState()
        }

        teardownPlayer()
        self.playbackRate = playbackRate
        isPreparing = true
        publish()

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
            isPreparing = false
            publish()
            return makeState(durationOverride: preparedPlayback.duration)
        } catch {
            currentURL = nil
            accessSession?.invalidate()
            accessSession = nil
            isPreparing = false
            let state = makeState(errorMessage: error.localizedDescription)
            publish(state)
            throw error
        }
    }

    func togglePlayback() throws -> AudioPlaybackState {
        guard let player else { return makeState() }

        if player.isPlaying {
            player.pause()
            stopProgressTimer()
        } else {
            let didStart = player.play()
            player.rate = Float(playbackRate)
            guard didStart else {
                throw NSError(
                    domain: "StemHub.AudioPlayback",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "StemHub could not start audio playback for this file."]
                )
            }
            startProgressTimer()
        }

        publish()
        return makeState()
    }

    func stop() -> AudioPlaybackState {
        player?.pause()
        player?.currentTime = 0
        stopProgressTimer()
        publish()
        return makeState()
    }

    func seek(to time: Double) -> AudioPlaybackState {
        guard let player else { return makeState() }

        player.currentTime = max(0, min(time, player.duration))
        publish()
        return makeState()
    }

    func updatePlaybackRate(_ value: Double) -> AudioPlaybackState {
        playbackRate = value
        player?.rate = Float(value)
        if player?.isPlaying == true {
            _ = player?.play()
            player?.rate = Float(value)
        }
        publish()
        return makeState()
    }

    func dispose() {
        teardownPlayer()
        continuation?.finish()
        continuation = nil
    }
}

private extension AVAudioPlaybackController {
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
        currentURL = nil
        isPreparing = false
    }

    func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    func makeState(
        durationOverride: Double? = nil,
        errorMessage: String? = nil
    ) -> AudioPlaybackState {
        AudioPlaybackState(
            currentURL: currentURL,
            isPlaying: player?.isPlaying == true,
            isPreparing: isPreparing,
            currentTime: player?.currentTime ?? 0,
            duration: durationOverride ?? player?.duration ?? 0,
            playbackRate: playbackRate,
            errorMessage: errorMessage
        )
    }

    func publish(_ state: AudioPlaybackState? = nil) {
        continuation?.yield(state ?? makeState())
    }

    @objc
    func handleProgressTimerTick() {
        guard let player else { return }
        let state = makeState()
        guard abs(player.currentTime - state.currentTime) >= Self.minimumProgressDelta else {
            publish(state)
            return
        }
        publish(state)
    }
}

extension AVAudioPlaybackController: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopProgressTimer()
            self.publish()
        }
    }
}
