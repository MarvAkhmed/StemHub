//
//  ProjectWorkspaceContentView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct ProjectWorkspaceContentView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    @StateObject private var audioDeckViewModel: MultiStemPlaybackViewModel

    init(viewModel: ProjectDetailViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._audioDeckViewModel = StateObject(
            wrappedValue: MultiStemPlaybackViewModel(
                defaultPlaybackRate: viewModel.defaultPlaybackRate
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                contextHeader
                fileBrowserSection

                if let selectedFileURL = viewModel.selectedFileURL,
                   viewModel.selectedFileSupportsTimestamp {
                    playbackSection(url: selectedFileURL)
                }

                if let diff = viewModel.versionDiff {
                    diffSection(diff: diff)
                }

                if viewModel.selectedFileURL == nil && viewModel.versionDiff == nil {
                    ContentUnavailableView(
                        "Select a File",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Choose a file to preview audio comments, inspect MIDI, or review version changes.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .foregroundStyle(.white.opacity(0.92))
                }
            }
            .padding(.vertical, 2)
        }
        .onDisappear {
            audioDeckViewModel.dispose()
        }
    }
}

private extension ProjectWorkspaceContentView {
    var contextHeader: some View {
        ProjectDetailPanel(title: "Current Version", systemImage: "pianokeys") {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.workspaceTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(viewModel.workspaceSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(viewModel.selectedFileDisplayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Button(action: {
                    Task { await viewModel.openMIDIEditor() }
                }) {
                    Label(
                        viewModel.selectedFileIsMIDI ? "Open Selected MIDI" : "Edit MIDI",
                        systemImage: "plus"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
        }
    }

    var fileBrowserSection: some View {
        ProjectDetailPanel(title: "Files", systemImage: "folder") {
            VStack(alignment: .leading, spacing: 6) {
                fileBrowserToolbar

                if let errorMessage = audioDeckViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if viewModel.fileTree.isEmpty {
                    ContentUnavailableView(
                        "No Files Yet",
                        systemImage: "folder",
                        description: Text("Import audio or create MIDI content to start shaping this version.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .foregroundStyle(.white.opacity(0.92))
                } else {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.fileTree) { node in
                            FileTreePlayerNodeView(
                                node: node,
                                audioDeckViewModel: audioDeckViewModel,
                                selectedFileURL: selectedFileBinding
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 4)
        }
    }

    func playbackSection(url: URL) -> some View {
        ProjectDetailPanel(title: "Playback Comments", systemImage: "waveform") {
            AudioPlayerView(
                url: url,
                comments: viewModel.selectedFileComments,
                selectedTimestamp: selectedTimestampBinding,
                playbackPreparer: viewModel.audioPlaybackPreparer,
                defaultPlaybackRate: viewModel.defaultPlaybackRate
            )
        }
    }

    var fileBrowserToolbar: some View {
        HStack(spacing: 12) {
            Text("\(audioDeckViewModel.selectedURLs.count) selected")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Play All") {
                audioDeckViewModel.playSelected()
            }
            .buttonStyle(.borderedProminent)
            .disabled(audioDeckViewModel.selectedURLs.isEmpty)

            Button("Stop All") {
                audioDeckViewModel.stopAll()
            }
            .buttonStyle(.bordered)
            .disabled(audioDeckViewModel.selectedURLs.isEmpty && audioDeckViewModel.playingURLs.isEmpty)

            Spacer()

            HStack(spacing: 8) {
                Text("Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { audioDeckViewModel.playbackRate },
                        set: { audioDeckViewModel.updatePlaybackRate($0) }
                    ),
                    in: 0.5...1.5,
                    step: 0.05
                )
                .frame(width: 120)
                Text(String(format: "%.2fx", audioDeckViewModel.playbackRate))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .trailing)
            }
        }
        .padding(.bottom, 8)
    }

    func diffSection(diff: ProjectDiff) -> some View {
        ProjectDetailPanel(
            title: "Version Changes",
            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
        ) {
            DiffPreviewView(diff: diff)
                .frame(height: 240)
        }
    }

    var selectedFileBinding: Binding<URL?> {
        Binding(
            get: { viewModel.selectedFileURL },
            set: { newValue in
                guard newValue != viewModel.selectedFileURL else { return }
                Task { await viewModel.selectFile(newValue) }
            }
        )
    }

    var selectedTimestampBinding: Binding<Double?> {
        Binding(
            get: { viewModel.selectedCommentTimestamp },
            set: { viewModel.selectedCommentTimestamp = $0 }
        )
    }
}
