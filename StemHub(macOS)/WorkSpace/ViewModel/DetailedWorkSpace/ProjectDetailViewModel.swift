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
import FirebaseStorage

protocol ProjectDetailViewModelProtocol: ObservableObject {
    // UI state
    var project: Project { get }
    var projectName: String { get }
    var projectPosterImage: NSImage? { get }
    var versionHistory: [ProjectVersion] { get }
    var currentFiles: [MusicFile] { get }
    var selectedVersion: ProjectVersion? { get }
    var versionDiff: ProjectDiff? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var currentBranchName: String { get }
    var currentVersionNumber: String { get }
    var showRelocationAlert: Bool { get set }
    var currentVersionID: String? { get }
    var fileTree: [FileTreeNode] { get }
    var isAddingFiles: Bool { get }
    
    // Methods
    func loadVersionHistory() async
    func loadVersionDetails(versionID: String) async
    func loadFiles() async
    func pullLatest() async
    func commitChanges(message: String) async
    func importAudioFiles() async
    func fixFolderPath() async
    func relocateProjectFolder() async
    func updatePoster(_ image: NSImage) async
    func pushAllCommits() async
    func refreshFileTree()
}

final class ProjectDetailViewModel: ProjectDetailViewModelProtocol {
    
    // MARK: - Dependencies (all injected)
    private let authService: AuthServiceProtocol
    private let syncService: ProjectSyncService
    private let versionService: ProjectVersionService
    private let commitStorage: LocalCommitService
    private let fileService: ProjectFileService
    private let persistence: ProjectPersistenceStrategy
    private let network: ProjectNetworkStrategy
    private let bookmark: BookmarkStrategy
    private let fileScanner: FileScannerStrategy
    
    // MARK: - Published State (UI)
    @Published var project: Project
    @Published var versionHistory: [ProjectVersion] = []
    @Published var currentFiles: [MusicFile] = []
    @Published var selectedVersion: ProjectVersion?
    @Published var versionDiff: ProjectDiff?
    @Published var errorMessage: String?
    @Published var currentBranchName = "main"
    @Published var currentVersionNumber = "0"
    @Published var showRelocationAlert = false
    @Published var fileTree: [FileTreeNode] = []
    @Published var isLoading = false
    @Published var isLoadingMessage = "Loading..."
    @Published var isAddingFiles = false
    
    // Internal state
    private var localState: LocalProjectState
    private var pendingCommit: PendingCommit?
    private var pendingTempFiles: [String: URL] = [:]
    private var accessedFolderURL: URL?
    
    // Local commits storage
    private var localCommits: [LocalCommit] = []
    
    // MARK: - Computed Properties
    var projectName: String { project.name }
    var currentVersionID: String? { project.currentVersionID }
    private var currentUserID: String? { authService.currentUser?.id }
    
    var projectPosterImage: NSImage? {
        guard let base64 = project.posterBase64,
              let data = Data(base64Encoded: base64) else { return nil }
        return NSImage(data: data)
    }
    
    // MARK: - Init
    init(
        project: Project,
        localState: LocalProjectState,
        authService: AuthServiceProtocol,
        syncService: ProjectSyncService,
        versionService: ProjectVersionService,
        commitStorage: LocalCommitService,
        fileService: ProjectFileService,
        persistence: ProjectPersistenceStrategy = DefaultProjectPersistenceStrategy(),
        network: ProjectNetworkStrategy = DefaultProjectNetworkStrategy(),
        bookmark: BookmarkStrategy = DefaultBookmarkStrategy(),
        fileScanner: FileScannerStrategy = DefaultFileScannerStrategy()
    ) {
        self.project = project
        self.localState = localState
        self.authService = authService
        self.syncService = syncService
        self.versionService = versionService
        self.commitStorage = commitStorage
        self.fileService = fileService
        self.persistence = persistence
        self.network = network
        self.bookmark = bookmark
        self.fileScanner = fileScanner
        
        // Load local commits with cleanup
        self.localCommits = commitStorage.loadLocalCommitsAndCleanup(projectID: project.id)
    }
    
    deinit {
        accessedFolderURL?.stopAccessingSecurityScopedResource()
    }
    
    // MARK: - Public Methods
    
    func loadVersionHistory() async {
        setLoading(true)
        defer { Task { setLoading(false) } }
        
        do {
            let versions = try await versionService.fetchVersionHistory(projectID: project.id)
            self.versionHistory = versions
            
            if let current = versions.first(where: { $0.id == project.currentVersionID }) {
                self.currentVersionNumber = "\(current.versionNumber)"
                self.selectedVersion = current
            } else if let latest = versions.first {
                self.selectedVersion = latest
            }
            
            if let savedBranchID = persistence.getCurrentBranchID(for: project.id), !savedBranchID.isEmpty {
                localState.currentBranchID = savedBranchID
            }
            
            if let branchID = localState.currentBranchID, !branchID.isEmpty {
                let branchDoc = try await network.getFirestore().collection("branches").document(branchID).getDocument()
                if let branch = try? branchDoc.data(as: Branch.self) {
                    self.currentBranchName = branch.name
                }
            }
        } catch {
            setError("Failed to load version history: \(error.localizedDescription)")
        }
    }
    
    func loadVersionDetails(versionID: String) async {
        guard !versionID.isEmpty else { return }
        setLoading(true)
        defer { Task { setLoading(false) } }
        
        do {
            guard let version = try await versionService.fetchVersion(versionID: versionID) else {
                setError("Version not found")
                return
            }
            self.selectedVersion = version
            self.versionDiff = (versionID != project.currentVersionID) ? version.diff : nil
            self.currentFiles = try await versionService.fetchFiles(for: version)
        } catch {
            setError("Failed to load version details: \(error.localizedDescription)")
        }
    }
    
    func loadFiles() async {
        let localPath = fileService.localPath(for: project.id)
        self.fileTree = fileService.fileTree(for: project.id, localPath: localPath)
        
        guard let folderURL = getAccessibleFolderURL() else {
            setError("Cannot access project folder.")
            return
        }
        
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
            refreshFileTree()
        } catch {
            setError("Failed to load files: \(error.localizedDescription)")
        }
    }
    
    func pullLatest() async {
        let unsynced = localCommits.filter { !$0.isPushed }
        guard unsynced.isEmpty else {
            setError("You have \(unsynced.count) unsynced commit(s). Please push them before pulling.")
            return
        }
        
        guard let branchID = localState.currentBranchID, !branchID.isEmpty else {
            setError("No branch selected")
            return
        }
        
        setLoading(true)
        defer { Task { setLoading(false) } }
        
        do {
            let newState = try await syncService.pull(
                projectID: project.id,
                branchID: branchID,
                localPath: localState.localPath
            )
            localState = newState
            persistence.setLastPulledVersionID(localState.lastPulledVersionID, for: project.id)
            await loadVersionHistory()
            await loadFiles()
        } catch {
            setError("Pull failed: \(error.localizedDescription)")
        }
    }
    
    func commitChanges(message: String) async {
        guard let pending = pendingCommit else {
            setError("No pending changes to commit")
            return
        }
        
        guard let currentUserID = getValidatedUserID() else { return }
        
        guard !message.isEmpty else {
            setError("Commit message cannot be empty")
            return
        }
        
        guard let branchID = localState.currentBranchID, !branchID.isEmpty else {
            setError("No branch selected")
            return
        }
        
        // Check remote head
        do {
            let branchDoc = try await network.getFirestore().collection("branches").document(branchID).getDocument()
            guard let branch = try? branchDoc.data(as: Branch.self),
                  let remoteHead = branch.headVersionID else {
                setError("Cannot fetch remote branch head")
                return
            }
            let lastPulled = localState.lastPulledVersionID ?? ""
            if remoteHead != lastPulled {
                setError("Remote has new commits. Please pull latest before committing.")
                return
            }
        } catch {
            setError("Failed to check remote status: \(error.localizedDescription)")
            return
        }
        
        setLoading(true)
        defer { Task { setLoading(false) } }
        
        let commitID = UUID().uuidString
        let commitCacheFolder = commitStorage.cacheFolder(for: project.id).appendingPathComponent(commitID, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: commitCacheFolder, withIntermediateDirectories: true)
            
            var finalSnapshots: [CommitFileSnapshot] = []
            for snapshot in pending.files {
                guard let tempURL = pendingTempFiles[snapshot.hash] else {
                    throw NSError(domain: "Missing temp file for hash \(snapshot.hash)", code: -1)
                }
                let destURL = commitCacheFolder.appendingPathComponent(snapshot.path)
                try FileManager.default.copyItem(at: tempURL, to: destURL)
                finalSnapshots.append(snapshot)
            }
            
            // Convert pending files to LocalFile array
            let localFiles: [LocalFile] = pending.files.map { snapshot in
                LocalFile(
                    path: snapshot.path,
                    name: (snapshot.path as NSString).lastPathComponent,
                    fileExtension: (snapshot.path as NSString).pathExtension,
                    size: 0,
                    hash: snapshot.hash,
                    isDirectory: false
                )
            }
            
            let commit = try await syncService.createCommit(
                projectID: project.id,
                branchID: branchID,
                localPath: localState.localPath,
                lastPulledVersionID: localState.lastPulledVersionID,
                files: localFiles,
                userID: currentUserID,
                message: message
            )
            
            let localCommit = LocalCommit(
                id: commitID,
                commit: commit,
                cachedFolderURL: commitCacheFolder,
                isPushed: false,
                createdAt: Date()
            )
            
            localCommits.append(localCommit)
            commitStorage.saveLocalCommits(localCommits, for: project.id)
            
            pendingCommit = nil
            pendingTempFiles.removeAll()
            localState.lastCommittedID = commitID
            
            await loadFiles()
            setError("Commit saved locally. Use 'Push' to upload.")
        } catch {
            setError("Failed to save commit locally: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: commitCacheFolder)
        }
    }
    
    func importAudioFiles() async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "Select Audio Files"
        guard panel.runModal() == .OK else { return }
        
        var localFiles: [LocalFile] = []
        var tempURLs: [String: URL] = [:]
        
        for url in panel.urls {
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
            try? FileManager.default.copyItem(at: url, to: tempURL)
            
            let localFile = LocalFileScanner().makeLocalFile(from: tempURL)
            localFiles.append(localFile)
            tempURLs[localFile.hash] = tempURL
        }
        
        var remoteSnapshot: [RemoteFileSnapshot] = []
        if let lastPulledID = localState.lastPulledVersionID, !lastPulledID.isEmpty {
            do {
                remoteSnapshot = try await network.fetchRemoteSnapshot(versionID: lastPulledID)
            } catch {
                setError("Failed to fetch remote snapshot: \(error.localizedDescription)")
                return
            }
        }
        
        let diffEngine = DefaultDiffEngineStrategy()
        let diffResult = diffEngine.computeDiff(local: localFiles, remote: remoteSnapshot)
        let projectDiff = diffEngine.mapToProjectDiff(diffResult)
        
        let commitSnapshots = localFiles.map { file in
            CommitFileSnapshot(
                fileID: UUID().uuidString,
                path: file.path,
                blobID: file.hash,
                hash: file.hash,
                versionNumber: 1
            )
        }
        
        self.pendingCommit = PendingCommit(
            files: commitSnapshots,
            diff: projectDiff,
            message: ""
        )
        self.pendingTempFiles = tempURLs
        
        await loadFiles()
        setError("\(localFiles.count) file(s) staged. Write a commit message and click Commit.")
    }
    
    func fixFolderPath() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select the project folder"
        guard panel.runModal() == .OK, let newURL = panel.url else { return }
        
        do {
            let bookmarkData = try bookmark.createBookmark(for: newURL)
            fileService.saveBookmark(bookmarkData, for: project.id)
            persistence.setLocalPath(newURL.path, for: project.id)
            
            localState = LocalProjectState(
                projectID: project.id,
                localPath: newURL.path,
                lastPulledVersionID: localState.lastPulledVersionID,
                lastCommittedID: localState.lastCommittedID,
                currentBranchID: localState.currentBranchID
            )
            await loadFiles()
            setError(nil)
        } catch {
            setError("Failed to update folder path: \(error.localizedDescription)")
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
            fileService.saveBookmark(bookmarkData, for: project.id)
            persistence.setLocalPath(newFolderURL.path, for: project.id)
            
            localState = LocalProjectState(
                projectID: project.id,
                localPath: newFolderURL.path,
                lastPulledVersionID: localState.lastPulledVersionID,
                lastCommittedID: localState.lastCommittedID,
                currentBranchID: localState.currentBranchID
            )
            await loadFiles()
            setError(nil)
            showRelocationAlert = false
        } catch {
            setError("Failed to relocate: \(error.localizedDescription)")
            showRelocationAlert = false
        }
    }
    
    func updatePoster(_ image: NSImage) async {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            setError("Failed to process image")
            return
        }
        let base64 = jpegData.base64EncodedString()
        
        do {
            try await network.getFirestore()
                .collection("projects")
                .document(project.id)
                .updateData(["posterBase64": base64])
            
            var updatedProject = project
            updatedProject.posterBase64 = base64
            project = updatedProject
            await loadFiles()
        } catch {
            setError("Failed to update poster: \(error.localizedDescription)")
        }
    }
    
    func pushAllCommits() async {
        let unsynced = localCommits.filter { !$0.isPushed }
        guard !unsynced.isEmpty else { return }
        
        setLoading(true)
        defer { Task { setLoading(false) } }
        
        guard let branchID = localState.currentBranchID, !branchID.isEmpty else {
            setError("No branch selected")
            return
        }
        
        var currentUnsynced = unsynced
        var index = 0
        
        while index < currentUnsynced.count {
            let localCommit = currentUnsynced[index]
            do {
                let newVersion = try await syncService.pushCommit(
                    localCommit.commit,
                    branchID: branchID,
                    localRootURL: localCommit.cachedFolderURL
                )
                
                localState.lastPulledVersionID = newVersion.id
                persistence.setLastPulledVersionID(newVersion.id, for: project.id)
                localState.lastCommittedID = localCommit.commit.id
                
                if let idx = localCommits.firstIndex(where: { $0.id == localCommit.id }) {
                    localCommits[idx].isPushed = true
                }
                try? FileManager.default.removeItem(at: localCommit.cachedFolderURL)
                commitStorage.saveLocalCommits(localCommits, for: project.id)
                await loadVersionHistory()
                await loadFiles()
                
                index += 1
            } catch SyncError.outdatedCommit {
                do {
                    let branchDoc = try await network.getFirestore().collection("branches").document(branchID).getDocument()
                    guard let branch = try? branchDoc.data(as: Branch.self),
                          let newHead = branch.headVersionID else {
                        throw NSError(domain: "Cannot fetch remote head", code: -1)
                    }
                    let rebased = try await syncService.rebaseCommit(localCommit, onto: newHead, projectID: project.id)
                    if let idx = localCommits.firstIndex(where: { $0.id == localCommit.id }) {
                        localCommits[idx] = rebased
                    }
                    commitStorage.saveLocalCommits(localCommits, for: project.id)
                    currentUnsynced[index] = rebased
                } catch {
                    setError("Rebase failed: \(error.localizedDescription)")
                    return
                }
            } catch {
                setError("Push failed for commit \(localCommit.id): \(error.localizedDescription)")
                return
            }
        }
        setError("All commits pushed successfully!")
    }
    
    func refreshFileTree() {
        let localPath = fileService.localPath(for: project.id)
        fileTree = fileService.fileTree(for: project.id, localPath: localPath)
    }
    
    // MARK: - Private Helpers
    
    private func getAccessibleFolderURL() -> URL? {
        if let url = accessedFolderURL {
            return url
        }
        
        let bookmarkData = UserDefaults.standard.data(forKey: "project_\(project.id)_bookmark")
        let localPath = fileService.localPath(for: project.id)
        
        guard let url = fileService.accessibleFolderURL(for: project.id,
                                                         bookmarkData: bookmarkData,
                                                         localPath: localPath) else {
            print("⚠️ Cannot get accessible folder URL for project: \(project.id)")
            return nil
        }
        
        // Start accessing and store
        let didStart = url.startAccessingSecurityScopedResource()
        if !didStart {
            print("⚠️ Failed to start accessing security-scoped resource")
            return nil
        }
        
        accessedFolderURL = url
        return url
    }
    
    private func getValidatedUserID() -> String? {
        guard let userID = currentUserID else {
            Task { setError("User not logged in") }
            return nil
        }
        return userID
    }
    
    // MARK: - UI Helpers
    
    @MainActor
    private func setLoading(_ loading: Bool, message: String = "Loading...") {
        isLoading = loading
        isLoadingMessage = message
    }
    
    @MainActor
    private func setError(_ message: String?) {
        errorMessage = message
    }
}
