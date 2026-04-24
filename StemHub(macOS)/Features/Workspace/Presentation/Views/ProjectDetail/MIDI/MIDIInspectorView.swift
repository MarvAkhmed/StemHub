//
//  MIDIInspectorView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct MIDIInspectorView: View {
    @ObservedObject var viewModel: MIDIEditorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                trackSection
                captureSection
                selectedEventSection
                documentSection
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.10, blue: 0.16),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private extension MIDIInspectorView {
    var trackSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Track Name", text: selectedTrackNameBinding)
                    .textFieldStyle(.roundedBorder)

                Stepper(value: selectedTrackChannelBinding, in: 1...16) {
                    Text("Track Channel: \(selectedTrackChannelBinding.wrappedValue)")
                }
            }
        } label: {
            Label("Track", systemImage: "music.note.list")
                .font(.headline)
        }
    }

    var captureSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(viewModel.controllerStatusText)
                        .font(.subheadline)
                    Spacer()
                    Button(viewModel.isRecording ? "Stop" : "Record") {
                        viewModel.toggleRecording()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if viewModel.connectedControllers.isEmpty {
                    Text("StemHub listens to every controller macOS exposes through CoreMIDI. Connect a keyboard, pad controller, foot controller, or automation surface to record into this track.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.connectedControllers) { controller in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(controller.isOnline ? Color.green : Color.secondary.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 5)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(controller.name)
                                        .font(.subheadline)
                                    Text(controller.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Text(viewModel.lastCaptureSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } label: {
            Label("Controller Capture", systemImage: "dot.radiowaves.left.and.right")
                .font(.headline)
        }
    }

    @ViewBuilder
    var selectedEventSection: some View {
        switch viewModel.activePanel {
        case .notes:
            noteSection
        case .controllers:
            controllerSection
        }
    }

    var noteSection: some View {
        GroupBox {
            if viewModel.selectedNote != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Stepper(value: selectedNoteStartBinding, in: 0...max(viewModel.document.totalBeats + 16, 16), step: 0.25) {
                        Text("Start Beat: \(viewModel.beatLabel(selectedNoteStartBinding.wrappedValue))")
                    }

                    Stepper(value: selectedNoteDurationBinding, in: 0.25...32, step: 0.25) {
                        Text("Duration: \(viewModel.beatLabel(selectedNoteDurationBinding.wrappedValue))")
                    }

                    Stepper(value: selectedNoteNumberBinding, in: 0...127) {
                        Text("Pitch: \(viewModel.noteLabel(UInt8(selectedNoteNumberBinding.wrappedValue)))")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Velocity: \(selectedNoteVelocityBinding.wrappedValue)")
                            .font(.subheadline)
                        Slider(
                            value: Binding(
                                get: { Double(selectedNoteVelocityBinding.wrappedValue) },
                                set: { viewModel.updateSelectedNoteVelocity(Int($0.rounded())) }
                            ),
                            in: 1...127,
                            step: 1
                        )
                    }

                    Stepper(value: selectedNoteChannelBinding, in: 1...16) {
                        Text("Channel: \(selectedNoteChannelBinding.wrappedValue)")
                    }

                    Button("Delete Note", role: .destructive) {
                        viewModel.deleteSelectedNote()
                    }
                }
            } else {
                Text("Select a note row to edit timing, pitch, and velocity.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } label: {
            Label("Selected Note", systemImage: "music.note")
                .font(.headline)
        }
    }

    var controllerSection: some View {
        GroupBox {
            if viewModel.selectedControllerEvent != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Stepper(value: selectedControllerBeatBinding, in: 0...max(viewModel.document.totalBeats + 16, 16), step: 0.25) {
                        Text("Beat: \(viewModel.beatLabel(selectedControllerBeatBinding.wrappedValue))")
                    }

                    Stepper(value: selectedControllerNumberBinding, in: 0...127) {
                        Text("Controller: CC \(selectedControllerNumberBinding.wrappedValue)")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Value: \(selectedControllerValueBinding.wrappedValue)")
                            .font(.subheadline)
                        Slider(
                            value: Binding(
                                get: { Double(selectedControllerValueBinding.wrappedValue) },
                                set: { viewModel.updateSelectedControllerValue(Int($0.rounded())) }
                            ),
                            in: 0...127,
                            step: 1
                        )
                    }

                    Stepper(value: selectedControllerChannelBinding, in: 1...16) {
                        Text("Channel: \(selectedControllerChannelBinding.wrappedValue)")
                    }

                    Button("Delete Controller Event", role: .destructive) {
                        viewModel.deleteSelectedControllerEvent()
                    }
                }
            } else {
                Text("Select a controller row to edit its beat position and value.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } label: {
            Label("Selected Controller", systemImage: "dial.medium")
                .font(.headline)
        }
    }

    var documentSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.document.relativePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)

                Stepper(value: tempoBinding, in: 30...240, step: 1) {
                    Text("Tempo: \(Int(viewModel.tempoBPM.rounded())) BPM")
                }

                Text(viewModel.saveStatusText)
                    .font(.caption)
                    .foregroundColor(viewModel.hasUnsavedChanges ? .orange : .secondary)
            }
        } label: {
            Label("Document", systemImage: "doc")
                .font(.headline)
        }
    }

    var selectedTrackNameBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedTrackName },
            set: { viewModel.updateSelectedTrackName($0) }
        )
    }

    var selectedTrackChannelBinding: Binding<Int> {
        Binding(
            get: { viewModel.selectedTrackChannel },
            set: { viewModel.updateSelectedTrackChannel($0) }
        )
    }

    var selectedNoteStartBinding: Binding<Double> {
        Binding(
            get: { viewModel.selectedNote?.startBeat ?? 0 },
            set: { viewModel.updateSelectedNoteStartBeat($0) }
        )
    }

    var selectedNoteDurationBinding: Binding<Double> {
        Binding(
            get: { viewModel.selectedNote?.durationBeats ?? 1 },
            set: { viewModel.updateSelectedNoteDuration($0) }
        )
    }

    var selectedNoteNumberBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.selectedNote?.noteNumber ?? 60) },
            set: { viewModel.updateSelectedNoteNumber($0) }
        )
    }

    var selectedNoteVelocityBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.selectedNote?.velocity ?? 100) },
            set: { viewModel.updateSelectedNoteVelocity($0) }
        )
    }

    var selectedNoteChannelBinding: Binding<Int> {
        Binding(
            get: { Int((viewModel.selectedNote?.channel ?? 0) + 1) },
            set: { viewModel.updateSelectedNoteChannel($0) }
        )
    }

    var selectedControllerBeatBinding: Binding<Double> {
        Binding(
            get: { viewModel.selectedControllerEvent?.beat ?? 0 },
            set: { viewModel.updateSelectedControllerBeat($0) }
        )
    }

    var selectedControllerNumberBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.selectedControllerEvent?.controllerNumber ?? 1) },
            set: { viewModel.updateSelectedControllerNumber($0) }
        )
    }

    var selectedControllerValueBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.selectedControllerEvent?.value ?? 64) },
            set: { viewModel.updateSelectedControllerValue($0) }
        )
    }

    var selectedControllerChannelBinding: Binding<Int> {
        Binding(
            get: { Int((viewModel.selectedControllerEvent?.channel ?? 0) + 1) },
            set: { viewModel.updateSelectedControllerChannel($0) }
        )
    }

    var tempoBinding: Binding<Double> {
        Binding(
            get: { viewModel.tempoBPM },
            set: { viewModel.updateTempo($0) }
        )
    }
}
