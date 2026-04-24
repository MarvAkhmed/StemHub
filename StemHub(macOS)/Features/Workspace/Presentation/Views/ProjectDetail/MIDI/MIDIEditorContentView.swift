//
//  MIDIEditorContentView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct MIDIEditorContentView: View {
    @ObservedObject var viewModel: MIDIEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            summaryCard

            if viewModel.isLoading {
                loadingState
            } else if viewModel.selectedTrack == nil {
                emptyState
            } else {
                pickerSection
                contentSection
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.10, blue: 0.18),
                    Color(red: 0.08, green: 0.08, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private extension MIDIEditorContentView {
    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.session.projectName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text(viewModel.session.contextCaption)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.68))
                    Text(viewModel.document.relativePath)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.54))
                        .textSelection(.enabled)
                }

                Spacer()

                HStack(spacing: 10) {
                    transportPill("\(Int(viewModel.tempoBPM.rounded())) BPM")
                    transportPill("\(viewModel.tracks.count) tracks")
                    transportPill(viewModel.saveStatusText)
                }
            }

            MIDIPianoRollOverviewView(
                notes: viewModel.selectedTrackNotes,
                totalBeats: max(viewModel.document.totalBeats, 16)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    func transportPill(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(Color.white.opacity(0.10))
            )
    }

    var contentCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    @ViewBuilder
    var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text("Loading MIDI document…")
                .foregroundColor(.white.opacity(0.72))
            Spacer()
        }
    }

    var emptyState: some View {
        ContentUnavailableView(
            "Select a Track",
            systemImage: "music.note.list",
            description: Text("Choose a track from the sidebar to edit notes and controller automation.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.white.opacity(0.88))
    }

    var pickerSection: some View {
        Picker("Editor Mode", selection: $viewModel.activePanel) {
            ForEach(MIDIEditorPanel.allCases) { panel in
                Text(panel.title).tag(panel)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 260)
        .colorScheme(.dark)
    }

    @ViewBuilder
    var contentSection: some View {
        switch viewModel.activePanel {
        case .notes:
            notesSection
        case .controllers:
            controllerSection
        }
    }

    var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "music.note")
                .font(.headline)
                .foregroundStyle(.white)

            if viewModel.selectedTrackNotes.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "music.note",
                    description: Text("Add a note or record from a connected MIDI controller.")
                )
                .frame(maxWidth: .infinity, minHeight: 380)
                .foregroundStyle(.white.opacity(0.88))
            } else {
                Table(viewModel.selectedTrackNotes, selection: selectedNoteBinding) {
                    TableColumn("Start") { note in
                        Text(viewModel.beatLabel(note.startBeat))
                    }
                    TableColumn("Duration") { note in
                        Text(viewModel.beatLabel(note.durationBeats))
                    }
                    TableColumn("Pitch") { note in
                        Text(viewModel.noteLabel(note.noteNumber))
                    }
                    TableColumn("Velocity") { note in
                        Text("\(note.velocity)")
                    }
                    TableColumn("Channel") { note in
                        Text(viewModel.channelLabel(note.channel))
                    }
                }
                .frame(minHeight: 380)
            }
        }
        .padding(18)
        .background(contentCardBackground)
    }

    var controllerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Controllers", systemImage: "dial.medium")
                .font(.headline)
                .foregroundStyle(.white)

            if viewModel.selectedTrackControllerEvents.isEmpty {
                ContentUnavailableView(
                    "No Controller Data",
                    systemImage: "dial.medium",
                    description: Text("Add a controller event or record automation from any connected MIDI controller.")
                )
                .frame(maxWidth: .infinity, minHeight: 380)
                .foregroundStyle(.white.opacity(0.88))
            } else {
                Table(viewModel.selectedTrackControllerEvents, selection: selectedControllerBinding) {
                    TableColumn("Beat") { event in
                        Text(viewModel.beatLabel(event.beat))
                    }
                    TableColumn("Controller") { event in
                        Text("CC \(event.controllerNumber)")
                    }
                    TableColumn("Value") { event in
                        Text("\(event.value)")
                    }
                    TableColumn("Channel") { event in
                        Text(viewModel.channelLabel(event.channel))
                    }
                }
                .frame(minHeight: 380)
            }
        }
        .padding(18)
        .background(contentCardBackground)
    }

    var selectedNoteBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedNoteID },
            set: { viewModel.selectNote($0) }
        )
    }

    var selectedControllerBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedControllerEventID },
            set: { viewModel.selectControllerEvent($0) }
        )
    }
}
