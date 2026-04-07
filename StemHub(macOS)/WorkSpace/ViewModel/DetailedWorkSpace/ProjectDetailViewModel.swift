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
    @Published var project: Project
    @Published var versionHistory: [ProjectVersion] = []
    @Published var currentFiles: [MusicFile] = []
    @Published var selectedVersion: ProjectVersion?
    @Published var versionDiff: ProjectDiff?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentBranchName = "main"
    @Published var currentVersionNumber = "0"
    @Published var showRelocationAlert = false
    @Published var pendingCommit: PendingCommit?
    @Published var fileTree: [FileTreeNode] = []
    private var accessedFolderURL: URL?
    
    
    func refreshFileTree() {
        fileTree = buildFileTree()
    }
    
    private func buildFileTree() -> [FileTreeNode] {
        guard let folderURL = getAccessibleFolderURL() else { return [] }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        
        func buildNode(at url: URL) -> FileTreeNode? {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            var node = FileTreeNode(url: url, isDirectory: isDirectory)
            if isDirectory {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    var childNodes: [FileTreeNode] = []
                    for childURL in contents {
                        if let childNode = buildNode(at: childURL) {
                            childNodes.append(childNode)
                        }
                    }
                    node.children = childNodes
                } catch {
                    print("Failed to read directory \(url): \(error)")
                }
            } else {
                node.children = nil
            }
            return node
        }
        
        return buildNode(at: folderURL)?.children ?? []
    }
    
    var currentVersionID: String? { project.currentVersionID }
    private var pendingTempFiles: [String: URL] = [:]
    
    // MARK: - Dependencies
    private var localState: LocalProjectState
    private let currentUserID: String?
    private let persistence: ProjectPersistenceStrategy
    private let network: ProjectNetworkStrategy
    private let bookmark: BookmarkStrategy
    private let fileScanner: FileScannerStrategy
    
    // MARK: - Local Commits Storage
    private var localCommits: [LocalCommit] = []
    private let commitsDirectory: URL
    private let localCommitsFileURL: URL
    
    
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
         bookmark: BookmarkStrategy,
         fileScanner: FileScannerStrategy) {
        self.project = project
        self.localState = localState
        self.currentUserID = currentUserID
        self.persistence = persistence
        self.network = network
        self.bookmark = bookmark
        self.fileScanner = fileScanner
        
        // Setup local commits folder
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let baseFolder = appSupport.appendingPathComponent("StemHub/Commits", isDirectory: true)
        try? FileManager.default.createDirectory(at: baseFolder, withIntermediateDirectories: true)
        self.commitsDirectory = baseFolder.appendingPathComponent(project.id, isDirectory: true)
        try? FileManager.default.createDirectory(at: commitsDirectory, withIntermediateDirectories: true)
        
        self.localCommitsFileURL = commitsDirectory.appendingPathComponent("local_commits.json")
        
        loadLocalCommits()
    }
    
    deinit {
        accessedFolderURL?.stopAccessingSecurityScopedResource()
    }
    
    convenience init(project: Project,
                     localState: LocalProjectState,
                     currentUserID: String?) {
        self.init(
            project: project,
            localState: localState,
            currentUserID: currentUserID,
            persistence: DefaultProjectPersistenceStrategy(),
            network: DefaultProjectNetworkStrategy(),
            bookmark: DefaultBookmarkStrategy(),
            fileScanner: DefaultFileScannerStrategy()
        )
    }
    
    // MARK: - Public Methods
    
    func loadVersionHistory() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let query = network.getFirestore().collection("projectVersions")
                .whereField("projectID", isEqualTo: project.id)
                .order(by: "versionNumber", descending: true)
            let snapshot = try await query.getDocuments()
            let versions = snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
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
            self.versionDiff = (versionID != project.currentVersionID) ? version.diff : nil
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
            errorMessage = "Failed to load files: \(error.localizedDescription)"
        }
    }
    
    func pullLatest() async {
        // Prevent pull if there are unsynced local commits
        let unsynced = localCommits.filter { !$0.isPushed }
        guard unsynced.isEmpty else {
            errorMessage = "You have \(unsynced.count) unsynced commit(s). Please push them before pulling."
            return
        }
        
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
    
    // MARK: - Commit (Local only, no push)
    func commitChanges(message: String) async {
        // 1. Validate pending commit exists
        guard let pending = pendingCommit else {
            errorMessage = "No pending changes to commit"
            return
        }
        
        // 2. Validate user is logged in
        guard let currentUserID = currentUserID else {
            errorMessage = "User not logged in"
            return
        }
        
        // 3. Validate commit message is not empty
        guard !message.isEmpty else {
            errorMessage = "Commit message cannot be empty"
            return
        }
        
        // 4. Check remote branch head – ensure we're committing against the latest version
        guard let branchID = localState.currentBranchID, !branchID.isEmpty else {
            errorMessage = "No branch selected"
            return
        }
        
        do {
            let branchDoc = try await network.getFirestore().collection("branches").document(branchID).getDocument()
            guard let branch = try? branchDoc.data(as: Branch.self),
                  let remoteHead = branch.headVersionID else {
                errorMessage = "Cannot fetch remote branch head"
                return
            }
            
            let lastPulled = localState.lastPulledVersionID ?? ""
            if remoteHead != lastPulled {
                errorMessage = "Remote has new commits. Please pull latest before committing."
                return
            }
        } catch {
            errorMessage = "Failed to check remote status: \(error.localizedDescription)"
            return
        }
        
        // 5. Proceed with local commit creation
        isLoading = true
        defer { isLoading = false }
        
        let commitID = UUID().uuidString
        let commitCacheFolder = commitsDirectory.appendingPathComponent(commitID, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: commitCacheFolder, withIntermediateDirectories: true)
            
            // Copy temp files to permanent cache folder
            var finalSnapshots: [CommitFileSnapshot] = []
            for snapshot in pending.files {
                guard let tempURL = pendingTempFiles[snapshot.hash] else {
                    throw NSError(domain: "Missing temp file for hash \(snapshot.hash)", code: -1)
                }
                let destURL = commitCacheFolder.appendingPathComponent(snapshot.path)
                try FileManager.default.copyItem(at: tempURL, to: destURL)
                finalSnapshots.append(snapshot)
            }
            
            // Create the Commit object
            let commit = Commit(
                id: commitID,
                projectID: project.id,
                parentCommitID: localState.lastCommittedID,
                basedOnVersionID: localState.lastPulledVersionID ?? "",
                diff: pending.diff,
                fileSnapshot: finalSnapshots,
                createdBy: currentUserID,
                createdAt: Date(),
                message: message,
                status: .local
            )
            
            let localCommit = LocalCommit(
                id: commitID,
                commit: commit,
                cachedFolderURL: commitCacheFolder,
                isPushed: false,
                createdAt: Date()
            )
            
            localCommits.append(localCommit)
            saveLocalCommits()
            
            // Clear pending
            pendingCommit = nil
            pendingTempFiles.removeAll()
            
            // Update local state
            localState.lastCommittedID = commitID
            
            await loadFiles()
            errorMessage = "Commit saved locally. Use 'Push' to upload."
            
        } catch {
            errorMessage = "Failed to save commit locally: \(error.localizedDescription)"
            try? FileManager.default.removeItem(at: commitCacheFolder)
        }
    }
    
    // MARK: - Push all unsynced commits
    
    private func rebaseCommit(_ localCommit: LocalCommit, onto newBaseVersionID: String) async throws -> LocalCommit {
        // 1. Fetch the new remote snapshot
        let newRemoteSnapshot = try await network.fetchRemoteSnapshot(versionID: newBaseVersionID)
        
        // 2. Get local files from cached folder
        var localFiles: [LocalFile] = []
        for snapshot in localCommit.commit.fileSnapshot {
            let fileURL = localCommit.cachedFolderURL.appendingPathComponent(snapshot.path)
            let hash = LocalFileScanner.hashFile(at: fileURL)
            let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
            let localFile = LocalFile(
                path: snapshot.path,
                name: (snapshot.path as NSString).lastPathComponent,
                fileExtension: (snapshot.path as NSString).pathExtension,
                size: size,
                hash: hash,
                isDirectory: false
            )
            localFiles.append(localFile)
        }
        
        // 3. Compute new diff against new remote snapshot
        let diffEngine = DefaultDiffEngineStrategy()
        let diffResult = diffEngine.computeDiff(local: localFiles, remote: newRemoteSnapshot)
        let newDiff = diffEngine.mapToProjectDiff(diffResult)
        
        // 4. Create new commit with updated basedOnVersionID
        let newCommitID = UUID().uuidString
        let newCommitCacheFolder = commitsDirectory.appendingPathComponent(newCommitID, isDirectory: true)
        try FileManager.default.createDirectory(at: newCommitCacheFolder, withIntermediateDirectories: true)
        
        // Copy files from old cache to new cache
        for snapshot in localCommit.commit.fileSnapshot {
            let srcURL = localCommit.cachedFolderURL.appendingPathComponent(snapshot.path)
            let dstURL = newCommitCacheFolder.appendingPathComponent(snapshot.path)
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        }
        
        let newCommit = Commit(
            id: newCommitID,
            projectID: localCommit.commit.projectID,
            parentCommitID: localCommit.commit.parentCommitID,
            basedOnVersionID: newBaseVersionID,   // updated base
            diff: newDiff,
            fileSnapshot: localCommit.commit.fileSnapshot,
            createdBy: localCommit.commit.createdBy,
            createdAt: Date(),
            message: localCommit.commit.message,
            status: .local
        )
        
        let rebasedLocalCommit = LocalCommit(
            id: newCommitID,
            commit: newCommit,
            cachedFolderURL: newCommitCacheFolder,
            isPushed: false,
            createdAt: Date()
        )
        
        // Remove old commit
        try? FileManager.default.removeItem(at: localCommit.cachedFolderURL)
        return rebasedLocalCommit
    }
    
    func pushAllCommits() async {
        let unsynced = localCommits.filter { !$0.isPushed }
        guard !unsynced.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        guard let branchID = localState.currentBranchID, !branchID.isEmpty else {
            errorMessage = "No branch selected"
            return
        }
        
        var currentUnsynced = unsynced
        var index = 0
        
        while index < currentUnsynced.count {
            let localCommit = currentUnsynced[index]
            do {
                let newVersion = try await network.pushCommit(
                    localCommit.commit,
                    localRootURL: localCommit.cachedFolderURL,
                    branchID: branchID
                )
                
                // Success
                localState.lastPulledVersionID = newVersion.id
                persistence.setLastPulledVersionID(newVersion.id, for: project.id)
                localState.lastCommittedID = localCommit.commit.id
                
                if let idx = localCommits.firstIndex(where: { $0.id == localCommit.id }) {
                    localCommits[idx].isPushed = true
                }
                try? FileManager.default.removeItem(at: localCommit.cachedFolderURL)
                print("🗑️ Removed cache folder: \(localCommit.cachedFolderURL.path)")
                saveLocalCommits()
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
                    
                    let rebased = try await rebaseCommit(localCommit, onto: newHead)
                    
                    if let idx = localCommits.firstIndex(where: { $0.id == localCommit.id }) {
                        localCommits[idx] = rebased
                    }
                    saveLocalCommits()
                    currentUnsynced[index] = rebased
                    // Retry same index
                } catch {
                    errorMessage = "Rebase failed: \(error.localizedDescription)"
                    return
                }
            } catch {
                errorMessage = "Push failed for commit \(localCommit.id): \(error.localizedDescription)"
                return
            }
        }
        
        errorMessage = "All commits pushed successfully!"
    }
    
    // MARK: - Import (stage files)
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
            // Create a temporary copy
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
                errorMessage = "Failed to fetch remote snapshot: \(error.localizedDescription)"
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
        
        await loadFiles() // UI refresh
        errorMessage = "\(localFiles.count) file(s) staged. Write a commit message and click Commit."
    }
    
    private func setupPanel() -> NSOpenPanel? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "Select Audio Files"
        guard panel.runModal() == .OK else { return nil }
        return panel
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
        if let url = accessedFolderURL {
            return url
        }
        guard let bookmarkData = UserDefaults.standard.data(forKey: "project_\(project.id)_bookmark") else {
            let url = URL(fileURLWithPath: localState.localPath)
            accessedFolderURL = url
            return url
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
            let didStart = url.startAccessingSecurityScopedResource()
            if !didStart {
                print("Failed to start accessing security-scoped resource")
                return nil
            }
            accessedFolderURL = url
            return url
        } catch {
            print("Bookmark resolution error: \(error)")
            return nil
        }
    }
    
//    private func getAccessibleFolderURL() -> URL? {
//        guard let bookmarkData = UserDefaults.standard.data(forKey: "project_\(project.id)_bookmark") else {
//            return URL(fileURLWithPath: localState.localPath)
//        }
//        var isStale = false
//        do {
//            let url = try URL(resolvingBookmarkData: bookmarkData,
//                              options: .withSecurityScope,
//                              relativeTo: nil,
//                              bookmarkDataIsStale: &isStale)
//            if isStale {
//                Task { await refreshBookmark() }
//                return nil
//            }
//            // ✅ MUST call this before accessing the folder
//            let didStart = url.startAccessingSecurityScopedResource()
//            if !didStart {
//                print("Failed to start accessing security-scoped resource")
//                return nil
//            }
//            return url
//        } catch {
//            print("Bookmark resolution error: \(error)")
//            return nil
//        }
//    }
    
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
    
    private func loadLocalCommits() {
        guard let data = try? Data(contentsOf: localCommitsFileURL),
              let commits = try? JSONDecoder().decode([LocalCommit].self, from: data) else {
            localCommits = []
            return
        }
        localCommits = commits
    }
    
    private func saveLocalCommits() {
        guard let data = try? JSONEncoder().encode(localCommits) else { return }
        try? data.write(to: localCommitsFileURL)
    }
    
    private func ensureBlobExists(blobID: String, fileURL: URL) async throws {
        let db = Firestore.firestore()
        let blobRef = db.collection("blobs").document(blobID)
        let snapshot = try await blobRef.getDocument()
        if !snapshot.exists {
            let storageRef = Storage.storage().reference().child("blobs/\(blobID)")
            _ = try await storageRef.putFileAsync(from: fileURL)
            let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
            let blob = FileBlob(id: blobID, storagePath: storageRef.fullPath, size: size, hash: blobID, createdAt: Date())
            try blobRef.setData(from: blob)
        }
    }
    
//    func buildNode(at url: URL) -> FileTreeNode? {
//        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
//        var node = FileTreeNode(url: url, isDirectory: isDirectory)
//        if isDirectory {
//            do {
//                let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
//                var childNodes: [FileTreeNode] = []
//                for childURL in contents {
//                    if let childNode = buildNode(at: childURL) {
//                        childNodes.append(childNode)
//                    }
//                }
//                node.children = childNodes   // assign non‑nil only for directories
//            } catch {
//                print("Failed to read directory \(url): \(error)")
//            }
//        } else {
//            node.children = nil
//        }
//        return node
//    }
    
//    private func getAccessibleFolderURL() -> URL? {
//        if let url = accessedFolderURL {
//            return url
//        }
//        guard let bookmarkData = UserDefaults.standard.data(forKey: "project_\(project.id)_bookmark") else {
//            let url = URL(fileURLWithPath: localState.localPath)
//            accessedFolderURL = url
//            return url
//        }
//        var isStale = false
//        do {
//            let url = try URL(resolvingBookmarkData: bookmarkData,
//                              options: .withSecurityScope,
//                              relativeTo: nil,
//                              bookmarkDataIsStale: &isStale)
//            if isStale {
//                Task { await refreshBookmark() }
//                return nil
//            }
//            let didStart = url.startAccessingSecurityScopedResource()
//            if !didStart {
//                print("Failed to start accessing security-scoped resource")
//                return nil
//            }
//            accessedFolderURL = url
//            return url
//        } catch {
//            print("Bookmark resolution error: \(error)")
//            return nil
//        }
//    }
}
