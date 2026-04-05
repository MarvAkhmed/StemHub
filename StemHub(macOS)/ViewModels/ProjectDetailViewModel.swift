//
//  ProjectDetailViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Combine
import UniformTypeIdentifiers

@MainActor
class ProjectDetailViewModel: ObservableObject {
    @Published var versionHistory: [ProjectVersion] = []
    @Published var currentFiles: [MusicFile] = []
    @Published var selectedVersion: ProjectVersion?
    @Published var versionDiff: ProjectDiff?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentBranchName = "main"
    @Published var currentVersionNumber = "0"
    @Published var currentVersionID: String?
    
    private let project: Project
    private var localState: LocalProjectState
    private let currentUserID: String?
    private let firestore = FirestoreManager.shared
    private let syncOrchestrator = SyncOrchestrator()
    private let scanner = LocalFileScanner()
    
    @Published var showRelocationAlert = false
    
    var onCommitRequested: (() -> Void)?
    
    init(project: Project, localState: LocalProjectState, currentUserID: String?) {
        self.project = project
        self.localState = localState
        self.currentUserID = currentUserID
        self.currentVersionID = project.currentVersionID
    }
    
    
    @MainActor
    func fixFolderPath() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select the project folder (now on Desktop)"
        guard panel.runModal() == .OK, let newFolderURL = panel.url else { return }
        
        do {
            // Create a new security‑scoped bookmark
            let bookmarkData = try newFolderURL.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "project_\(project.id)_bookmark")
            UserDefaults.standard.set(newFolderURL.path, forKey: "project_\(project.id)_path")
            
            // Update local state
            localState = LocalProjectState(
                projectID: project.id,
                localPath: newFolderURL.path,
                lastPulledVersionID: localState.lastPulledVersionID,
                lastCommittedID: localState.lastCommittedID,
                currentBranchID: localState.currentBranchID
            )
            await loadFiles()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to update folder path: \(error.localizedDescription)"
        }
    }
    
    
    func loadVersionHistory() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try with ordering first (requires index)
            do {
                let versionsSnapshot = try await firestore.firestore()
                    .collection("projectVersions")
                    .whereField("projectID", isEqualTo: project.id)
                    .order(by: "versionNumber", descending: true)
                    .getDocuments()
                
                let versions = versionsSnapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
                self.versionHistory = versions
                
                if let currentVersion = versions.first(where: { $0.id == project.currentVersionID }) {
                    self.currentVersionNumber = "\(currentVersion.versionNumber)"
                    self.selectedVersion = currentVersion
                } else if let latest = versions.first {
                    self.selectedVersion = latest
                }
                
            } catch {
                // If index doesn't exist, fetch without ordering and sort locally
                print("⚠️ Index not ready, fetching without order: \(error)")
                
                let snapshot = try await firestore.firestore()
                    .collection("projectVersions")
                    .whereField("projectID", isEqualTo: project.id)
                    .getDocuments()
                
                var versions = snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
                versions.sort { $0.versionNumber > $1.versionNumber }
                self.versionHistory = versions
                
                if let currentVersion = versions.first(where: { $0.id == project.currentVersionID }) {
                    self.currentVersionNumber = "\(currentVersion.versionNumber)"
                    self.selectedVersion = currentVersion
                } else if let latest = versions.first {
                    self.selectedVersion = latest
                }
                
                // Show user-friendly message about index
                if !versions.isEmpty {
                    errorMessage = "Firestore index is being created. Results are shown without sorting. The app will work better once the index is ready."
                }
            }
            
            // Load branch name
            if let branchID = localState.currentBranchID, !branchID.isEmpty {
                let branchDoc = try await firestore.firestore()
                    .collection("branches")
                    .document(branchID)
                    .getDocument()
                if let branch = try? branchDoc.data(as: Branch.self) {
                    self.currentBranchName = branch.name
                }
            }
            
        } catch {
            errorMessage = "Failed to load version history: \(error.localizedDescription)"
            print("❌ Error loading version history: \(error)")
        }
    }
    
    func loadVersionDetails(versionID: String) async {
        // Guard against empty version ID
        guard !versionID.isEmpty else {
            errorMessage = "Invalid version ID"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch the selected version
            let versionDoc = try await firestore.firestore()
                .collection("projectVersions")
                .document(versionID)
                .getDocument()
            
            let version = try versionDoc.data(as: ProjectVersion.self)
            self.selectedVersion = version
            
            // Calculate diff if not current version
            if versionID != project.currentVersionID {
                self.versionDiff = version.diff
            } else {
                self.versionDiff = nil
            }
            
            // Load files for this version
            await loadFilesForVersion(version)
            
        } catch {
            errorMessage = "Failed to load version details: \(error.localizedDescription)"
            print("❌ Error loading version details: \(error)")
        }
    }
    
    private func loadFilesForVersion(_ version: ProjectVersion) async {
        var files: [MusicFile] = []
        
        for fileVersionID in version.fileVersionIDs {
            guard !fileVersionID.isEmpty else { continue }
            
            do {
                let fvDoc = try await firestore.firestore()
                    .collection("fileVersions")
                    .document(fileVersionID)
                    .getDocument()
                
                let fileVersion = try fvDoc.data(as: FileVersion.self)
                
                let musicFile = MusicFile(
                    id: fileVersion.fileID,
                    projectID: project.id,
                    name: (fileVersion.path as NSString).lastPathComponent,
                    fileExtension: (fileVersion.path as NSString).pathExtension,
                    path: fileVersion.path,
                    capabilities: FileCapabilities.playable,
                    currentVersionID: fileVersion.id,
                    availableFormats: [],
                    createdAt: fileVersion.createdAt
                )
                files.append(musicFile)
            } catch {
                print("Failed to load file version \(fileVersionID): \(error)")
            }
        }
        
        self.currentFiles = files
    }
    
    func loadFiles() async {
        guard let folderURL = getAccessibleFolderURL() else {
            errorMessage = "Cannot access project folder."
            return
        }
        
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { folderURL.stopAccessingSecurityScopedResource() }
        }
        
        do {
            let localFiles = try scanner.scan(folderURL: folderURL)
            self.currentFiles = localFiles.filter { !$0.isDirectory }.map {
                MusicFile(
                    id: $0.id,
                    projectID: project.id,
                    name: $0.name,
                    fileExtension: $0.fileExtension,
                    path: $0.path,
                    capabilities: FileCapabilities.playable,
                    currentVersionID: "",
                    availableFormats: [],
                    createdAt: Date()
                )
            }
        } catch {
            errorMessage = "Failed to load files: \(error.localizedDescription)"
        }
    }
    
    func pullLatest() async {
        guard let branchID = localState.currentBranchID, !branchID.isEmpty else {
            errorMessage = "No branch selected"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            localState = try await firestore.pullProject(
                projectID: project.id,
                branchID: branchID,
                localRootURL: URL(fileURLWithPath: localState.localPath),
                state: localState
            )
            
            // Update current version
            self.currentVersionID = localState.lastPulledVersionID
            await loadVersionHistory()
            await loadFiles()
            
        } catch {
            errorMessage = "Pull failed: \(error.localizedDescription)"
        }
    }
    
    func commitChanges(message: String) async {
        guard let currentUserID = currentUserID else {
            errorMessage = "User not logged in"
            return
        }
        
        guard !message.isEmpty else {
            errorMessage = "Commit message cannot be empty"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            var remoteSnapshot: [RemoteFileSnapshot] = []
            if let lastPulledID = localState.lastPulledVersionID, !lastPulledID.isEmpty {
                remoteSnapshot = try await firestore.fetchRemoteSnapshot(versionID: lastPulledID)
            }
            
            let commit = try await syncOrchestrator.commit(
                localPath: URL(fileURLWithPath: localState.localPath),
                localState: localState,
                remoteSnapshot: remoteSnapshot,
                userID: currentUserID,
                message: message
            )
            
            if let branchID = localState.currentBranchID, !branchID.isEmpty {
                let _ = try await firestore.pushCommit(
                    commit,
                    localRootURL: URL(fileURLWithPath: localState.localPath),
                    branchID: branchID
                )
                localState.lastCommittedID = commit.id
                
                // Refresh version history
                await loadVersionHistory()
                await loadFiles()
            }
            
        } catch {
            errorMessage = "Commit failed: \(error.localizedDescription)"
            print("❌ Commit error: \(error)")
        }
    }
    
    @MainActor
    func importAudioFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "Select Audio Files"
        
        guard panel.runModal() == .OK else { return }
        
        guard let folderURL = getAccessibleFolderURL() else {
            errorMessage = "Cannot access project folder. Please re‑select the folder."
            return
        }
        
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { folderURL.stopAccessingSecurityScopedResource() }
        }
        
        for url in panel.urls {
            let destination = folderURL.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: url, to: destination)
                print("Imported: \(url.lastPathComponent)")
            } catch {
                errorMessage = "Failed to import \(url.lastPathComponent): \(error.localizedDescription). Would you like to relocate the project folder to a writable location?"
                self.showRelocationAlert = true
                return
            }
        }
        
        Task {
            await loadFiles()
            await MainActor.run { self.onCommitRequested?() }
        }
    }
    
    func refreshBookmark() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select the project folder again"
        guard panel.runModal() == .OK, let newURL = panel.url else { return }
        
        do {
            let bookmarkData = try newURL.bookmarkData(options: .minimalBookmark,
                                                       includingResourceValuesForKeys: nil,
                                                       relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: "project_\(project.id)_bookmark")
            UserDefaults.standard.set(newURL.path, forKey: "project_\(project.id)_path")
            
            localState = LocalProjectState(
                projectID: project.id,
                localPath: newURL.path,
                lastPulledVersionID: localState.lastPulledVersionID,
                lastCommittedID: localState.lastCommittedID,
                currentBranchID: localState.currentBranchID
            )
            await loadFiles()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save new bookmark: \(error.localizedDescription)"
        }
    }
    
    private func getAccessibleFolderURL() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "project_\(project.id)_bookmark") else {
            // Fallback to plain path (may not be writable)
            return URL(fileURLWithPath: localState.localPath)
        }
        
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmarkData,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale) else {
            return nil
        }
        
        if isStale {
            // Bookmark is stale – the folder was moved. Ask user to relocate.
            Task { await refreshBookmark() }
            return nil
        }
        
        return url
    }
    
    @MainActor
    func relocateProjectFolder() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select a NEW writable folder for this project"
        panel.message = "The current folder is not writable. Choose a folder in Documents or Desktop."
        guard panel.runModal() == .OK, let newFolderURL = panel.url else {
            showRelocationAlert = false
            return
        }
        
        let oldFolderURL = URL(fileURLWithPath: localState.localPath)
        let didStartAccessing = oldFolderURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { oldFolderURL.stopAccessingSecurityScopedResource() } }
        
        do {
            // If the new folder already exists, remove it (or merge – here we replace)
            if FileManager.default.fileExists(atPath: newFolderURL.path) {
                try FileManager.default.removeItem(at: newFolderURL)
            }
            // Move the entire folder contents
            try FileManager.default.moveItem(at: oldFolderURL, to: newFolderURL)
            
            // Create new security‑scoped bookmark
            let bookmarkData = try newFolderURL.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "project_\(project.id)_bookmark")
            UserDefaults.standard.set(newFolderURL.path, forKey: "project_\(project.id)_path")
            
            // Update local state
            localState = LocalProjectState(
                projectID: project.id,
                localPath: newFolderURL.path,
                lastPulledVersionID: localState.lastPulledVersionID,
                lastCommittedID: localState.lastCommittedID,
                currentBranchID: localState.currentBranchID
            )
            await loadFiles()
            errorMessage = nil
            showRelocationAlert = false
        } catch {
            errorMessage = "Failed to relocate: \(error.localizedDescription)"
            showRelocationAlert = false
        }
    }
}
