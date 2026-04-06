//
//  ProjectDetailViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import UniformTypeIdentifiers

@MainActor
protocol ProjectDetailViewModelProtocol: ObservableObject {
    var versionHistory: [ProjectVersion] { get }
    var currentFiles: [MusicFile] { get }
    var selectedVersion: ProjectVersion? { get }
    var versionDiff: ProjectDiff? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get set }
    var currentBranchName: String { get }
    var currentVersionNumber: String { get }
    var showRelocationAlert: Bool { get set }
    var currentVersionID: String? { get }
    var projectName: String { get }
    var projectPosterImage: NSImage? { get }
    
    func loadVersionHistory() async
    func loadVersionDetails(versionID: String) async
    func loadFiles() async
    func pullLatest() async
    func commitChanges(message: String) async
    func importAudioFiles() async
    func fixFolderPath() async
    func relocateProjectFolder() async
}

@MainActor
final class ProjectDetailViewModel: ProjectDetailViewModelProtocol {
    
    // MARK: - Published Properties
    @Published var versionHistory: [ProjectVersion] = []
    @Published var currentFiles: [MusicFile] = []
    @Published var selectedVersion: ProjectVersion?
    @Published var versionDiff: ProjectDiff?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentBranchName = "main"
    @Published var currentVersionNumber = "0"
    @Published var showRelocationAlert = false
    
    var currentVersionID: String? { project.currentVersionID }
    
    // MARK: - Dependencies (Injected)
    @Published var project: Project
    private var localState: LocalProjectState
    private let currentUserID: String?
    private let persistence: ProjectPersistenceStrategy
    private let network: ProjectNetworkStrategy
    private let sync: ProjectSyncStrategy
    private let bookmark: BookmarkStrategy
    private let fileScanner: FileScannerStrategy
    
    var projectName: String { project.name }
    
    var projectPosterImage: NSImage? {
        guard let base64 = project.posterBase64,
              let data = Data(base64Encoded: base64) else { return nil }
        return NSImage(data: data)
    }
    // MARK: - Init
    init(project: Project,
           localState: LocalProjectState,
           currentUserID: String?,
           persistence: ProjectPersistenceStrategy,
           network: ProjectNetworkStrategy,
           sync: ProjectSyncStrategy,
           bookmark: BookmarkStrategy,
         fileScanner: FileScannerStrategy) {
        self.project = project
        self.localState = localState
        self.currentUserID = currentUserID
        self.persistence = persistence
        self.network = network
        self.sync = sync
        self.bookmark = bookmark
        self.fileScanner = fileScanner
    }
    
    convenience init(project: Project,
                        localState: LocalProjectState,
                     currentUserID: String?) {
        self.init(
            project: project,
            localState: localState,
            currentUserID: currentUserID,
            persistence: ProjectPersistenceService(),
            network: ProjectNetworkService(),
            sync: ProjectSyncService(),
            bookmark: BookmarkService(),
            fileScanner: DefaultFileScannerStrategy()
        )
    }
    
    // MARK: - Public Methods
    
    func loadVersionHistory() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch version history from Firestore
            let query = network.getFirestore().collection("projectVersions")
                .whereField("projectID", isEqualTo: project.id)
                .order(by: "versionNumber", descending: true)
            let snapshot = try await query.getDocuments()
            let versions = snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
            self.versionHistory = versions
            
            // Select the current version or latest
            if let current = versions.first(where: { $0.id == project.currentVersionID }) {
                self.currentVersionNumber = "\(current.versionNumber)"
                self.selectedVersion = current
            } else if let latest = versions.first {
                self.selectedVersion = latest
            }
            
            // Restore the saved branch ID (if any)
            if let savedBranchID = persistence.getCurrentBranchID(for: project.id), !savedBranchID.isEmpty {
                localState.currentBranchID = savedBranchID
            }
            
            // Fetch branch name using the current branch ID
            if let branchID = localState.currentBranchID, !branchID.isEmpty {
                let branchDoc = try await network.getFirestore().collection("branches").document(branchID).getDocument()
                if let branch = try? branchDoc.data(as: Branch.self) {
                    self.currentBranchName = branch.name
                }
            }
        } catch {
            errorMessage = "Failed to load version history: \(error.localizedDescription)"
        }
    }
    
    func loadVersionDetails(versionID: String) async {
        guard !versionID.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let versionDoc = try await network.getFirestore().collection("projectVersions").document(versionID).getDocument()
            let version = try versionDoc.data(as: ProjectVersion.self)
            self.selectedVersion = version
            
            if versionID != project.currentVersionID {
                self.versionDiff = version.diff
            } else {
                self.versionDiff = nil
            }
            
            await loadFilesForVersion(version)
        } catch {
            errorMessage = "Failed to load version details: \(error.localizedDescription)"
        }
    }
    
    func loadFiles() async {
   
        guard let folderURL = getAccessibleFolderURL() else {
            errorMessage = "Cannot access project folder."
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource()}
        
//        let didStart = folderURL.startAccessingSecurityScopedResource()
//        defer { if didStart { folderURL.stopAccessingSecurityScopedResource() } }
        
        do {
            let localFiles = try fileScanner.scan(folderURL: folderURL)
            self.currentFiles = localFiles.filter { !$0.isDirectory }.map {
                MusicFile(
                    id: $0.id,
                    projectID: project.id,
                    name: $0.name,
                    fileExtension: $0.fileExtension,
                    path: $0.path,
                    capabilities: .playable,
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
            localState = try await network.pullProject(
                projectID: project.id,
                branchID: branchID,
                localRootURL: URL(fileURLWithPath: localState.localPath),
                state: localState
            )
            persistence.setLastPulledVersionID(localState.lastPulledVersionID, for: project.id)
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
                remoteSnapshot = try await network.fetchRemoteSnapshot(versionID: lastPulledID)
            }
            
            let commit = try await sync.commit(
                localPath: URL(fileURLWithPath: localState.localPath),
                localState: localState,
                remoteSnapshot: remoteSnapshot,
                userID: currentUserID,
                message: message
            )
            
            if let branchID = localState.currentBranchID, !branchID.isEmpty {
                let newVersion = try await network.pushCommit(commit, localRootURL: URL(fileURLWithPath: localState.localPath), branchID: branchID)
                localState.lastPulledVersionID = newVersion.id
                persistence.setLastPulledVersionID(newVersion.id, for: project.id)
                localState.lastCommittedID = commit.id
                await loadVersionHistory()
                await loadFiles()
            }
        } catch {
            errorMessage = "Commit failed: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func importAudioFiles() async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "Select Audio Files"
        guard panel.runModal() == .OK else { return }
        
        guard let folderURL = getAccessibleFolderURL() else {
            errorMessage = "Cannot access project folder."
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        
        for url in panel.urls {
            let destination = folderURL.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: url, to: destination)
            } catch {
                errorMessage = "Failed to import \(url.lastPathComponent): \(error.localizedDescription)"
                showRelocationAlert = true
                return
            }
        }
        await loadFiles()
    }
    
    func fixFolderPath() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select the project folder"
        guard panel.runModal() == .OK, let newURL = panel.url else { return }
        
        do {
            let bookmarkData = try bookmark.createBookmark(for: newURL)
            persistence.storeBookmark(data: bookmarkData, for: project.id)
            persistence.setLocalPath(newURL.path, for: project.id)
            
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
            errorMessage = "Failed to update folder path: \(error.localizedDescription)"
        }
    }
    
    func relocateProjectFolder() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select a NEW writable folder"
        panel.message = "The current folder is not writable. Choose a writable location."
        guard panel.runModal() == .OK, let newFolderURL = panel.url else {
            showRelocationAlert = false
            return
        }
        
        let oldURL = URL(fileURLWithPath: localState.localPath)
        let didStart = oldURL.startAccessingSecurityScopedResource()
        defer { if didStart { oldURL.stopAccessingSecurityScopedResource() } }
        
        do {
            if FileManager.default.fileExists(atPath: newFolderURL.path) {
                try FileManager.default.removeItem(at: newFolderURL)
            }
            try FileManager.default.moveItem(at: oldURL, to: newFolderURL)
            let bookmarkData = try bookmark.createBookmark(for: newFolderURL)
            persistence.storeBookmark(data: bookmarkData, for: project.id)
            persistence.setLocalPath(newFolderURL.path, for: project.id)
            
            
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
    
    // MARK: - Private Helpers
    
    private func loadFilesForVersion(_ version: ProjectVersion) async {
        var files: [MusicFile] = []
        for fileVersionID in version.fileVersionIDs {
            guard !fileVersionID.isEmpty else { continue }
            do {
                let fvDoc = try await network.getFirestore().collection("fileVersions").document(fileVersionID).getDocument()
                let fileVersion = try fvDoc.data(as: FileVersion.self)
                let musicFile = MusicFile(
                    id: fileVersion.fileID,
                    projectID: project.id,
                    name: (fileVersion.path as NSString).lastPathComponent,
                    fileExtension: (fileVersion.path as NSString).pathExtension,
                    path: fileVersion.path,
                    capabilities: .playable,
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
    
    private func getAccessibleFolderURL() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "project_\(project.id)_bookmark") else {
            return URL(fileURLWithPath: localState.localPath)
        }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData,
                              options: .withSecurityScope,
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            if isStale {
                Task { await refreshBookmark() }
                return nil
            }
            // ✅ MUST call this before accessing the folder
            let didStart = url.startAccessingSecurityScopedResource()
            if !didStart {
                print("Failed to start accessing security-scoped resource")
                return nil
            }
            return url
        } catch {
            print("Bookmark resolution error: \(error)")
            return nil
        }
    }
    
    private func refreshBookmark() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select the project folder again"
        guard panel.runModal() == .OK, let newFolderURL = panel.url else { return }
        do {
            
            let bookmarkData = try bookmark.createBookmark(for: newFolderURL)
            persistence.storeBookmark(data: bookmarkData, for: project.id)
            
            persistence.setLocalPath(newFolderURL.path, for: project.id)
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
            errorMessage = "Failed to save new bookmark: \(error.localizedDescription)"
        }
    }
    
    func updatePoster(_ image: NSImage) async {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            errorMessage = "Failed to process image"
            return
        }
        let base64 = jpegData.base64EncodedString()
        
        do {
            try await network.getFirestore()
                .collection("projects")
                .document(project.id)
                .updateData(["posterBase64": base64])
            
            // Update local project
            var updatedProject = project
            updatedProject.posterBase64 = base64
            project = updatedProject
            await loadFiles() // refresh UI (optional)
        } catch {
            errorMessage = "Failed to update poster: \(error.localizedDescription)"
        }
    }
}
