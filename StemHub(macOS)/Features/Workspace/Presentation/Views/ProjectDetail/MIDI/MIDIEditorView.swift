//
//  MIDIEditorView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct MIDIEditorView: View {
    @StateObject private var viewModel: MIDIEditorViewModel

    init(viewModel: MIDIEditorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationSplitView {
            MIDITrackSidebarView(viewModel: viewModel)
        } content: {
            MIDIEditorContentView(viewModel: viewModel)
        } detail: {
            MIDIInspectorView(viewModel: viewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle(viewModel.document.displayName)
        .navigationSubtitle(viewModel.session.contextCaption)
        .frame(minWidth: 1220, minHeight: 820)
        .toolbar { toolbarContent }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onDisappear {
            viewModel.dispose()
        }
        .animation(.snappy(duration: 0.22), value: viewModel.activePanel)
        .animation(.snappy(duration: 0.22), value: viewModel.selectedTrackID)
        .alert("MIDI Editor", isPresented: errorBinding) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private extension MIDIEditorView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Menu {
                Button("Track", action: viewModel.addTrack)
                Button("Note", action: viewModel.addNote)
                Button("Controller Event", action: viewModel.addControllerEvent)
            } label: {
                Label("Add", systemImage: "plus")
            }

            Button(action: viewModel.toggleRecording) {
                Label(
                    viewModel.isRecording ? "Stop Recording" : "Record Controllers",
                    systemImage: viewModel.isRecording ? "stop.circle.fill" : "record.circle"
                )
            }

            Button(action: {
                Task { await viewModel.save() }
            }) {
                Label("Save MIDI", systemImage: "square.and.arrow.down")
            }
            .disabled(viewModel.isSaving || !viewModel.hasUnsavedChanges)

            if viewModel.isSaving {
                ProgressView()
            }
        }
    }

    var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearError()
                }
            }
        )
    }
}
