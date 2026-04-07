//
//  ProjectDetailView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

struct ProjectDetailView: View {
    @StateObject var viewModel: ProjectDetailViewModel
    @State private var selectedVersionID: String?
    @State private var showingCommitSheet = false
    @State private var commitMessage = ""

    @State private var selectedFileURL: URL?
    @State private var selectedAudioURL: URL?
    
    init(project: Project, localState: LocalProjectState, currentUserID: String?) {
        _viewModel = StateObject(wrappedValue: ProjectDetailViewModel(
            project: project,
            localState: localState,
            currentUserID: currentUserID
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            HSplitView {
                versionHistorySidebar
                    .frame(minWidth: 250, idealWidth: 280)
                mainContentView
                    .frame(minWidth: 400)
            }
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingCommitSheet) { commitSheet }
        .task {
            await viewModel.loadVersionHistory()
            await viewModel.loadFiles()
        }
        .alert("Folder Not Writable", isPresented: $viewModel.showRelocationAlert) {
            Button("Relocate") { Task { await viewModel.relocateProjectFolder() } }
            Button("Cancel", role: .cancel) { viewModel.showRelocationAlert = false }
        } message: {
            Text("The project folder is in a read‑only location. Would you like to move it to a writable folder?")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    func isDirectory(url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Poster
            if let image = viewModel.projectPosterImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "music.note").font(.title).foregroundColor(.gray))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.projectName)
                    .font(.largeTitle)
                    .bold()
                HStack(spacing: 16) {
                    Label("Branch: \(viewModel.currentBranchName)", systemImage: "arrow.triangle.branch")
                    Label("Version: \(viewModel.currentVersionNumber)", systemImage: "number.circle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView().padding()
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Version History Sidebar
    private var versionHistorySidebar: some View {
        List(selection: $selectedVersionID) {
            Section("Version History") {
                Button(action: {
                    selectedVersionID = nil
                    Task { await viewModel.loadFiles() }
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle")
                        Text("Current Version")
                            .font(.headline)
                        Spacer()
                        if selectedVersionID == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())

                ForEach(viewModel.versionHistory) { version in
                    VersionRowView(version: version, isSelected: selectedVersionID == version.id)
                        .tag(version.id)
                        .onTapGesture {
                            selectedVersionID = version.id
                            Task { await viewModel.loadVersionDetails(versionID: version.id) }
                        }
                }
            }
        }
        .listStyle(SidebarListStyle())
    }

   
//     MARK: - Main Content (File Browser + Diff)
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedVersion = viewModel.selectedVersion {
                HStack {
                    Text("Version \(selectedVersion.versionNumber)")
                        .font(.title2).bold()
                    Spacer()
                    Text(selectedVersion.createdAt, style: .date)
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                Divider()
            } else {
                HStack {
                    Text("Current Version (Local)")
                        .font(.title2).bold()
                    Spacer()
                    Button("Refresh") {
                        Task { await viewModel.loadFiles() }
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.top)
                Divider()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.fileTree) { node in
                        FileTreePlayerNodeView(node: node)
                    }
                    if viewModel.fileTree.isEmpty {
                        Text("No files or folders found.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }

            if let diff = viewModel.versionDiff,
               selectedVersionID != nil && selectedVersionID != viewModel.currentVersionID {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Changes from current version to this version")
                        .font(.headline)
                        .padding(.horizontal)
                    DiffPreviewView(diff: diff)
                        .frame(height: 200)
                }
            }
        }
    }
    
//    private var mainContentView: some View {
//        HSplitView {
//            // Left: File tree
//            FileTreeView(nodes: viewModel.fileTree, selectedFileURL: $selectedFileURL)
//                .frame(minWidth: 250, idealWidth: 300)
//                .onReceive(Just(selectedFileURL)) { newURL in
//                    if let url = newURL, !self.isDirectory(url: url) {
//                        selectedAudioURL = url
//                    }
//                }
//            
//            // Right: Audio player / empty state
//            VStack {
//                if let audioURL = selectedAudioURL {
//                    AudioPlayerView(url: audioURL)
//                        .padding()
//                    Spacer()
//                } else {
//                    ContentUnavailableView(
//                        "No Audio Selected",
//                        systemImage: "music.note.list",
//                        description: Text("Select an audio file from the left panel to play it.")
//                    )
//                }
//            }
//            .frame(minWidth: 300)
//            .background(Color(NSColor.textBackgroundColor))
//        }
//    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: { Task { await viewModel.pullLatest() } }) {
                Label("Pull", systemImage: "arrow.down.circle")
            }
            Button(action: { showingCommitSheet = true }) {
                Label("Commit", systemImage: "arrow.up.circle")
            }
            Button(action: { Task { await viewModel.importAudioFiles() } }) {
                Label("Add Files", systemImage: "plus.circle")
            }
        
            Button(action: { Task { await selectAndUpdatePoster() } }) {
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
        }
    }

    // MARK: - Commit Sheet
    private var commitSheet: some View {
        VStack(spacing: 20) {
            Text("Commit Changes").font(.title2)
            TextField("Commit message", text: $commitMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            HStack {
                Button("Cancel") {
                    showingCommitSheet = false
                    commitMessage = ""
                }
                Button("Commit") {
                    Task {
                        await viewModel.commitChanges(message: commitMessage)
                        showingCommitSheet = false
                        commitMessage = ""
                    }
                }
                .disabled(commitMessage.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
    
    
    private func selectAndUpdatePoster() async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let url = panel.url,
              let image = NSImage(contentsOf: url) else { return }
        await viewModel.updatePoster(image)
    }
}
