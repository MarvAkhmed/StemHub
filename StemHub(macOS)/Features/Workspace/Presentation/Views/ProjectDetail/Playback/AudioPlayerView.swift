//
//  AudioPlayerView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct AudioPlayerView: View {
    let url: URL
    let comments: [Comment]
    @Binding var selectedTimestamp: Double?
    @StateObject private var viewModel: AudioPlayerViewModel

    init(
        url: URL,
        comments: [Comment],
        selectedTimestamp: Binding<Double?>,
        playbackService: AudioPlaybackServicing,
        defaultPlaybackRate: Double
    ) {
        self.url = url
        self.comments = comments
        self._selectedTimestamp = selectedTimestamp
        self._viewModel = StateObject(
            wrappedValue: AudioPlayerViewModel(
                playbackService: playbackService,
                defaultPlaybackRate: defaultPlaybackRate
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(url.lastPathComponent)
                        .font(.headline)
                    Text("Playback: \(format(viewModel.currentTime)) / \(format(viewModel.duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let selectedTimestamp {
                    Text("Comment at \(format(selectedTimestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.isPreparing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Preparing local preview…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let playbackErrorMessage = viewModel.playbackErrorMessage {
                Text(playbackErrorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: viewModel.togglePlayback) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.duration <= 0 || viewModel.isPreparing)

                Button(action: viewModel.stop) {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.duration <= 0 || viewModel.isPreparing)

                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(viewModel.duration, 1)
                )
                .disabled(viewModel.duration <= 0 || viewModel.isPreparing)

                Button("Use Current Time") {
                    selectedTimestamp = viewModel.currentTime
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.duration <= 0 || viewModel.isPreparing)
            }

            HStack {
                Text("Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(
                    value: Binding(
                        get: { viewModel.playbackRate },
                        set: { viewModel.updatePlaybackRate($0) }
                    ),
                    in: 0.5...1.5,
                    step: 0.05
                )

                Text(String(format: "%.2fx", viewModel.playbackRate))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 48, alignment: .trailing)
            }

            CommentTimelineMarkersView(comments: comments, duration: viewModel.duration) { comment in
                selectedTimestamp = comment.timestamp
                if let timestamp = comment.timestamp {
                    viewModel.seek(to: timestamp)
                }
            }
        }
        .padding(.vertical, 4)
        .task(id: url) {
            await viewModel.load(url: url)
        }
        .onDisappear {
            viewModel.dispose()
        }
    }
}

private extension AudioPlayerView {
    func format(_ seconds: Double) -> String {
        let totalSeconds = max(Int(seconds.rounded(.down)), 0)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
