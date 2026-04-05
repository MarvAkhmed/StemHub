//
//  ProjectDetailView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct ProjectDetailView: View {
    let project: Project
    @StateObject private var viewModel: ProjectDetailViewModel
    @State private var selectedVersionID: String?
    @State private var showingCommitSheet = false
    @State private var commitMessage = ""
    @State private var showRelocationAlert = false
    
    init(project: Project, localState: LocalProjectState, currentUserID: String?) {
        self.project = project
        _viewModel = StateObject(wrappedValue: ProjectDetailViewModel(
            project: project,
            localState: localState,
            currentUserID: currentUserID
        ))
        
       
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with project info
            headerView
            
            Divider()
            
            // Main content - Use HStack instead of HSplitView to avoid constraints issues
            HStack(spacing: 0) {
                // Left: Version History
                versionHistorySidebar
                    .frame(minWidth: 250, idealWidth: 300, maxWidth: 350)
                    .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Right: File Browser
                fileBrowserView
                    .frame(minWidth: 400)
                    .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { Task { await viewModel.pullLatest() } }) {
                    Label("Pull", systemImage: "arrow.down.circle")
                }
                
                Button(action: { showingCommitSheet = true }) {
                    Label("Commit", systemImage: "arrow.up.circle")
                }
                
                Button(action: {  viewModel.importAudioFiles() }) {
                    Label("Add Files", systemImage: "plus.circle")
                }
                
                Button(action: { Task { await viewModel.loadVersionHistory() } }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                Button(action: { Task { await viewModel.fixFolderPath() } }) {
                    Label("Fix Path", systemImage: "folder.badge.gearshape")
                }
            }
        }
        .sheet(isPresented: $showingCommitSheet) {
            commitSheet
        }
        .task {
            await viewModel.loadVersionHistory()
            await viewModel.loadFiles()
        }
        .alert("Folder Not Writable", isPresented: $viewModel.showRelocationAlert) {
            Button("Relocate") {
                Task { await viewModel.relocateProjectFolder() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.showRelocationAlert = false
            }
        } message: {
            Text("The project folder is in a read‑only location. Would you like to move it to a writable folder?")
        }
        
          .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
              Button("OK") { viewModel.errorMessage = nil }
          } message: {
              Text(viewModel.errorMessage ?? "")
          }
        

    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Project poster
            if let posterURL = project.posterURL {
                AsyncImage(url: URL(string: posterURL)) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                        .overlay(ProgressView())
                }
//                .frame(width: 80, height: 80)
                .frame(width: 220, height: 160)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.largeTitle)
                    .bold()
                
                HStack(spacing: 16) {
                    // Branch label - fixed icon
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption)
                        Text("Branch: \(viewModel.currentBranchName)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // Version label
                    HStack(spacing: 4) {
                        Image(systemName: "number.circle")
                            .font(.caption)
                        Text("Version: \(viewModel.currentVersionNumber)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status indicators
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Version History Sidebar
    private var versionHistorySidebar: some View {
        List(selection: $selectedVersionID) {
            Section("Version History") {
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
    
    // MARK: - File Browser View
    private var fileBrowserView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Selected version info
            if let selectedVersion = viewModel.selectedVersion {
                HStack {
                    Text("Version \(selectedVersion.versionNumber)")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Text(selectedVersion.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
            }
            
            // File list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.currentFiles) { file in
                        FileRowView(file: file)
                    }
                }
                .padding()
            }
            
            // Diff preview if viewing older version
            if let diff = viewModel.versionDiff, selectedVersionID != viewModel.currentVersionID {
                Divider()
                DiffPreviewView(diff: diff)
                    .frame(height: 200)
            }
        }
    }
    
    // MARK: - Commit Sheet
    private var commitSheet: some View {
        VStack(spacing: 20) {
            Text("Commit Changes")
                .font(.title2)
            
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
}


// MARK: - Version Row View

// MARK: - File Row View
//struct FileRowView: View {
//    let file: MusicFile
//
//    var body: some View {
//        HStack {
//            Image(systemName: fileIcon(for: file))
//                .foregroundColor(.accentColor)
//                .frame(width: 24)
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text(file.name)
//                    .font(.body)
//
//                if !file.path.isEmpty {
//                    Text(file.path)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//
//            Spacer()
//
//            Text(file.fileExtension.uppercased())
//                .font(.caption)
//                .padding(4)
//                .background(Capsule().fill(Color.gray.opacity(0.2)))
//        }
//        .padding(.vertical, 4)
//    }
//
//    // MARK: - File Icon Helper
//    private func fileIcon(for file: MusicFile) -> String {
//        let fileType = determineFileType(from: file.fileExtension)
//
//        switch fileType {
//        case .audio:
//            return "music.note"
//        case .midi:
//            return "pianokeys"
//        case .project:
//            return "folder"
//        case .folder:
//            return "folder"
//        case .other:
//            return "doc"
//        }
//    }
//
//    private func determineFileType(from fileExtension: String) -> FileType {
//        let ext = fileExtension.lowercased()
//
//        switch ext {
//        case "mp3", "wav", "aac", "m4a", "flac", "ogg":
//            return .audio
//        case "mid", "midi":
//            return .midi
//        case "stemhub", "project":
//            return .project
//        default:
//            return .other
//        }
//    }
//}

// MARK: - Diff Preview View


//struct DiffChangeRow: View {
//    let diff: FileDiff
//
//    var body: some View {
//        HStack {
//            Image(systemName: iconForChangeType)
//                .foregroundColor(colorForChangeType)
//
//            Text(diff.path)
//                .font(.caption)
//
//            if diff.changeType == .renamed, let oldPath = diff.oldPath {
//                Text("(was: \(oldPath))")
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//            }
//
//            Spacer()
//
//            Text(changeTypeText)
//                .font(.caption)
//                .padding(4)
//                .background(Capsule().fill(colorForChangeType.opacity(0.2)))
//        }
//        .padding(.vertical, 2)
//    }
//
//    private var iconForChangeType: String {
//        switch diff.changeType {
//        case .added: return "plus.circle"
//        case .removed: return "minus.circle"
//        case .modified: return "pencil.circle"
//        case .renamed: return "arrow.left.arrow.right.circle"
//        }
//    }
//
//    private var colorForChangeType: Color {
//        switch diff.changeType {
//        case .added: return .green
//        case .removed: return .red
//        case .modified: return .orange
//        case .renamed: return .blue
//        }
//    }
//
//    private var changeTypeText: String {
//        switch diff.changeType {
//        case .added: return "Added"
//        case .removed: return "Removed"
//        case .modified: return "Modified"
//        case .renamed: return "Renamed"
//        }
//    }
//}
