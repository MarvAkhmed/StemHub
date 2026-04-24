//
//  MIDITrackSidebarView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct MIDITrackSidebarView: View {
    @ObservedObject var viewModel: MIDIEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            List(selection: trackSelectionBinding) {
                ForEach(viewModel.tracks) { track in
                    MIDITrackRowView(
                        track: track,
                        isSelected: viewModel.selectedTrackID == track.id,
                        channelLabel: viewModel.channelLabel(track.channel)
                    )
                    .tag(track.id)
                }
            }
            .listStyle(.sidebar)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private extension MIDITrackSidebarView {
    var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Tracks")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(viewModel.tracks.count) total")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.60))
            }

            Spacer()

            Button(action: viewModel.addTrack) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)

            Button(action: viewModel.removeSelectedTrack) {
                Image(systemName: "minus")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.tracks.count <= 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    var trackSelectionBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedTrackID },
            set: { viewModel.selectTrack($0) }
        )
    }
}

private struct MIDITrackRowView: View {
    let track: MIDITrack
    let isSelected: Bool
    let channelLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(track.name)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.white)
                Spacer()
                Text(channelLabel)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.56))
            }

            HStack(spacing: 10) {
                Label("\(track.notes.count)", systemImage: "music.note")
                Label("\(track.controllerEvents.count)", systemImage: "dial.medium")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.58))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.10) : .clear)
        )
    }
}
