//
//  ProjectDetailView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

private enum ProjectDetailLayout {
    static let minimumSplitContentWidth: CGFloat = 940
}

struct ProjectDetailView: View {
    @StateObject private var viewModel: ProjectDetailViewModel
    private let makeMIDIEditorViewModel: (ProjectMIDISession) -> MIDIEditorViewModel
    @State private var selectedSection: ProjectDetailSection = .workspace
    @State private var showingCommitSheet = false
    @State private var commitMessage = ""
    @State private var commitDraft: Commit?
    @State private var isLoadingCommitDraft = false
    @State private var deletionConsent = false

    init(
        viewModel: ProjectDetailViewModel,
        makeMIDIEditorViewModel: @escaping (ProjectMIDISession) -> MIDIEditorViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeMIDIEditorViewModel = makeMIDIEditorViewModel
    }

    var body: some View {
        ZStack {
            StudioBackdropView()

            VStack(spacing: 16) {
                ProjectDetailHeaderView(
                    viewModel: viewModel,
                    selectedSection: $selectedSection
                )

                splitContent
            }
            .studioSafeArea()
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingCommitSheet) { commitSheet }
        .navigationDestination(item: $viewModel.midiEditorSession) { session in
            MIDIEditorView(viewModel: makeMIDIEditorViewModel(session))
        }
        .onChange(of: viewModel.midiEditorSession?.id) { _, newValue in
            if newValue == nil {
                Task { await viewModel.loadFiles() }
            }
        }
        .task {
            await viewModel.loadInitialStateIfNeeded()
        }
        .alert("Folder Not Writable", isPresented: $viewModel.showRelocationAlert) {
            Button("Relocate") {
                Task { await viewModel.relocateProjectFolder() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.showRelocationAlert = false
            }
        } message: {
            Text("The project folder is in a read-only location. Move it to a writable folder to continue syncing.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearError()
                }
            }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private extension ProjectDetailView {
    var splitContent: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HSplitView {
                ProjectVersionHistorySidebar(viewModel: viewModel)
                    .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)

                ProjectDetailMainPane(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
                .frame(minWidth: 420)

                ProjectInspectorSidebarView(viewModel: viewModel)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
            }
            .frame(minWidth: ProjectDetailLayout.minimumSplitContentWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: { Task { await viewModel.pullLatest() } }) {
                Label("Pull", systemImage: "arrow.down.circle")
            }

            Button(action: { showingCommitSheet = true }) {
                Label("Commit", systemImage: "arrow.up.circle")
            }
            .disabled(!viewModel.canCommit)

            Button(action: { Task { await viewModel.importAudioFiles() } }) {
                Label("Import Audio", systemImage: "waveform.badge.plus")
            }

            Button(action: { Task { await viewModel.selectAndUpdatePoster() } }) {
                Label("Set Poster", systemImage: "photo")
            }

            Button(action: { Task { await viewModel.loadVersionHistory() } }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Button(action: { Task { await viewModel.fixFolderPath() } }) {
                Label("Fix Path", systemImage: "folder.badge.gearshape")
            }

            Button(action: { Task { await viewModel.pushAllCommits() } }) {
                Label("Push", systemImage: "arrow.up.circle.fill")
            }
            .disabled(viewModel.pendingCommitCount == 0)
        }
    }

    var commitSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Review Changes")
                .font(.title2.weight(.semibold))

            Text("Changes are staged locally first. If any files are removed, you must explicitly allow those deletions before the commit is created.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Commit message", text: $commitMessage)
                .textFieldStyle(.roundedBorder)

            GroupBox {
                if isLoadingCommitDraft {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Scanning modified files…")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
                } else if let commitDraft {
                    VStack(alignment: .leading, spacing: 14) {
                        if commitDraft.diff.files.isEmpty {
                            ContentUnavailableView(
                                "No Local Changes",
                                systemImage: "checkmark.circle",
                                description: Text("Add or edit files before creating a new commit.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 180)
                        } else {
                            DiffPreviewView(diff: commitDraft.diff)
                                .frame(minHeight: 240)

                            if commitDraft.diff.removed.isEmpty == false {
                                Toggle(
                                    "I approve deleting \(commitDraft.diff.removed.count) file\(commitDraft.diff.removed.count == 1 ? "" : "s") in this commit.",
                                    isOn: $deletionConsent
                                )
                                .studioToggleSwitch()
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Unable To Preview Changes",
                        systemImage: "exclamationmark.triangle",
                        description: Text("StemHub could not generate a change preview for this working copy.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                }
            }

            HStack {
                Button("Cancel") {
                    resetCommitSheetState()
                }

                Spacer()

                Button("Stage Commit") {
                    guard let commitDraft else { return }
                    Task {
                        let stagedCommit = stagedCommitFromDraft(commitDraft)
                        await viewModel.stageCommitDraft(stagedCommit)
                        resetCommitSheetState()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitButtonDisabled)
            }
        }
        .padding()
        .frame(width: 640, height: 520)
        .task {
            await loadCommitDraft()
        }
    }

    var commitButtonDisabled: Bool {
        guard let commitDraft else { return true }
        if commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        if commitDraft.diff.removed.isEmpty == false && !deletionConsent {
            return true
        }
        return commitDraft.diff.files.isEmpty
    }

    func loadCommitDraft() async {
        isLoadingCommitDraft = true
        deletionConsent = false
        commitDraft = await viewModel.prepareCommitDraft(
            message: commitMessage.isEmpty ? "Reviewing changes" : commitMessage,
            stagedFiles: nil
        )
        isLoadingCommitDraft = false
    }

    func stagedCommitFromDraft(_ draft: Commit) -> Commit {
        Commit(
            id: draft.id,
            projectID: draft.projectID,
            parentCommitID: draft.parentCommitID,
            basedOnVersionID: draft.basedOnVersionID,
            diff: draft.diff,
            fileSnapshot: draft.fileSnapshot,
            createdBy: draft.createdBy,
            createdAt: draft.createdAt,
            message: commitMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            status: draft.status
        )
    }

    func resetCommitSheetState() {
        showingCommitSheet = false
        commitMessage = ""
        commitDraft = nil
        deletionConsent = false
        isLoadingCommitDraft = false
    }
}
