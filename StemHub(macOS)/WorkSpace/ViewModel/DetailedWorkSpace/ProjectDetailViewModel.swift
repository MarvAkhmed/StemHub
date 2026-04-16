//
//  ProjectDetailViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

protocol ProjectDetailViewModelProtocol: ObservableObject {
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
    var currentVersionID: String? { get }          // Added
    var showRelocationAlert: Bool { get set }
    var fileTree: [FileTreeNode] { get }
    var isAddingFiles: Bool { get }

    func loadVersionHistory() async
    func loadVersionDetails(versionID: String) async
    func loadFiles() async
    func pullLatest() async
    func commitChanges(message: String, stagedFiles: [LocalFile]?) async   // Made optional
    func importAudioFiles() async
    func fixFolderPath() async
    func relocateProjectFolder() async
    func updatePoster(_ image: NSImage) async
    func pushAllCommits() async
    func refreshFileTree()
}

final class ProjectDetailViewModel: ProjectDetailViewModelProtocol {

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let syncService: ProjectSyncService
    private let versionService: ProjectVersionService
    private let localCommitStore: LocalCommitStore
    private let folderService: ProjectFolderService
    private let stateStore: ProjectStateStore
    private let branchRepository: BranchRepository
    private let projectRepository: ProjectRepository
    private let bookmarkStrategy: BookmarkStrategy
    private let fileScanner: FileScanner

    // MARK: - State
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

    private var localCommits: [LocalCommit] = []
    private var currentBranchID: String { project.currentBranchID }

    var projectName: String { project.name }
    private var currentUserID: String? { authService.currentUser?.id }

    var currentVersionID: String? { project.currentVersionID }   // Added

    var projectPosterImage: NSImage? {
        guard let base64 = project.posterBase64, let data = Data(base64Encoded: base64) else { return nil }
        return NSImage(data: data)
    }

    // MARK: - Init
    init(
        project: Project,
        authService: AuthServiceProtocol,
        syncService: ProjectSyncService = DefaultProjectSyncService(),
        versionService: ProjectVersionService = DefaultProjectVersionService(),
        localCommitStore: LocalCommitStore = DefaultLocalCommitStore(),
        folderService: ProjectFolderService = DefaultProjectFolderService(),
        stateStore: ProjectStateStore = UserDefaultsProjectStateStore(),
        branchRepository: BranchRepository = DefaultBranchRepository(),
        projectRepository: ProjectRepository = FirestoreProjectRepository(),
        bookmarkStrategy: BookmarkStrategy = DefaultBookmarkStrategy(),
        fileScanner: FileScanner = LocalFileScanner()
    ) {
        self.project = project
        self.authService = authService
        self.syncService = syncService
        self.versionService = versionService
        self.localCommitStore = localCommitStore
        self.folderService = folderService
        self.stateStore = stateStore
        self.branchRepository = branchRepository
        self.projectRepository = projectRepository
        self.bookmarkStrategy = bookmarkStrategy
        self.fileScanner = fileScanner

        self.localCommits = localCommitStore.loadLocalCommitsAndCleanup(projectID: project.id)

        Task {
            await loadVersionHistory()
            await loadFiles()
        }
    }

    // MARK: - Public Methods
    func loadVersionHistory() async {
        setLoading(true)
        defer { Task { setLoading(false) } }

        do {
            let versions = try await versionService.fetchVersionHistory(projectID: project.id)
            await MainActor.run {
                self.versionHistory = versions
                if let current = versions.first(where: { $0.id == project.currentVersionID }) {
                    self.currentVersionNumber = "\(current.versionNumber)"
                    self.selectedVersion = current
                } else if let latest = versions.first {
                    self.selectedVersion = latest
                }
            }

            if let branch = try? await branchRepository.fetchBranch(branchID: currentBranchID) {
                await MainActor.run { self.currentBranchName = branch.name }
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
            await MainActor.run {
                self.selectedVersion = version
                self.versionDiff = (versionID != project.currentVersionID) ? version.diff : nil
            }
            let files = try await versionService.fetchFiles(for: version)
            await MainActor.run { self.currentFiles = files }
        } catch {
            setError("Failed to load version details: \(error.localizedDescription)")
        }
    }

    func loadFiles() async {
        guard let folderURL = folderService.resolveFolderURL(for: project.id) else {
            setError("Cannot access project folder.")
            return
        }

        let tree = folderService.fileTree(for: project.id)
        await MainActor.run { self.fileTree = tree }

        do {
            let scannedFiles = try fileScanner.scan(folderURL: folderURL)
            let musicFiles = scannedFiles.filter { !$0.isDirectory }.map {
                MusicFile(
                    id: $0.id,
                    projectID: project.id,
                    name: $0.name,
                    fileExtension: $0.fileExtension,
                    path: $0.path,
                    capabilities: .playable,
                    currentVersionID: project.currentVersionID,
                    availableFormats: [],
                    createdAt: Date()
                )
            }
            await MainActor.run { self.currentFiles = musicFiles }
        } catch {
            setError("Failed to scan files: \(error.localizedDescription)")
        }
    }

    func pullLatest() async {
        let unsynced = localCommits.filter { !$0.isPushed }
        guard unsynced.isEmpty else {
            setError("You have \(unsynced.count) unsynced commit(s). Please push them before pulling.")
            return
        }

        setLoading(true)
        defer { Task { setLoading(false) } }

        do {
            let newState = try await syncService.pull(projectID: project.id, branchID: currentBranchID)
            stateStore.saveSyncState(newState)
            await loadVersionHistory()
            await loadFiles()
        } catch {
            setError("Pull failed: \(error.localizedDescription)")
        }
    }

    func commitChanges(message: String, stagedFiles: [LocalFile]?) async {
        guard let userID = currentUserID else {
            setError("User not logged in")
            return
        }
        guard !message.isEmpty else {
            setError("Commit message cannot be empty")
            return
        }

        setLoading(true, message: "Creating commit...")
        defer { Task { setLoading(false) } }

        do {
            // Determine which files to commit
            let filesToCommit: [LocalFile]
            if let staged = stagedFiles {
                filesToCommit = staged
            } else {
                guard let folderURL = folderService.resolveFolderURL(for: project.id) else {
                    setError("Cannot access project folder.")
                    return
                }
                let allFiles = try fileScanner.scan(folderURL: folderURL)
                filesToCommit = allFiles.filter { !$0.isDirectory }
            }

            // Check remote head before committing
            try await syncService.ensureRemoteHeadIsCurrent(projectID: project.id, branchID: currentBranchID)

            let commit = try await syncService.createCommit(
                projectID: project.id,
                branchID: currentBranchID,
                stagedFiles: filesToCommit,
                userID: userID,
                message: message
            )

            let cacheFolder = localCommitStore.cacheFolder(for: project.id)
                .appendingPathComponent(commit.id, isDirectory: true)
            try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)

            // Copy staged files to cache folder (simplified)
            for file in filesToCommit {
                let sourceURL = folderService.resolveFolderURL(for: project.id)!.appendingPathComponent(file.path)
                let destURL = cacheFolder.appendingPathComponent(file.path)
                try FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            }

            let localCommit = LocalCommit(
                id: commit.id,
                commit: commit,
                cachedFolderURL: cacheFolder,
                isPushed: false,
                createdAt: Date()
            )
            localCommits.append(localCommit)
            localCommitStore.saveLocalCommits(localCommits, for: project.id)

            setError("Commit saved locally. Use 'Push' to upload.")
        } catch {
            setError("Commit failed: \(error.localizedDescription)")
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
        for url in panel.urls {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            try? FileManager.default.copyItem(at: url, to: tempURL)
            localFiles.append(LocalFileScanner().makeLocalFile(from: tempURL))
        }

        isAddingFiles = true
        await commitChanges(message: "Imported \(localFiles.count) audio file(s)", stagedFiles: localFiles)
        isAddingFiles = false
    }

    func fixFolderPath() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select the project folder"
        guard panel.runModal() == .OK, let newURL = panel.url else { return }

        do {
            try folderService.updateFolderReference(projectID: project.id, folderURL: newURL)
            await loadFiles()
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

        let oldURL = folderService.resolveFolderURL(for: project.id)
        guard let oldURL else { return }

        let didStart = oldURL.startAccessingSecurityScopedResource()
        defer { if didStart { oldURL.stopAccessingSecurityScopedResource() } }

        do {
            if FileManager.default.fileExists(atPath: newFolderURL.path) {
                try FileManager.default.removeItem(at: newFolderURL)
            }
            try FileManager.default.moveItem(at: oldURL, to: newFolderURL)
            try folderService.updateFolderReference(projectID: project.id, folderURL: newFolderURL)
            await loadFiles()
            showRelocationAlert = false
        } catch {
            setError("Failed to relocate: \(error.localizedDescription)")
            showRelocationAlert = false
        }
    }

    func updatePoster(_ image: NSImage) async {
        guard let jpegData = image.jpegRepresentation(compression: 0.7) else {
            setError("Failed to process image")
            return
        }
        let base64 = jpegData.base64EncodedString()

        do {
            try await projectRepository.updatePosterBase64(projectID: project.id, base64: base64)
            var updated = project
            updated.posterBase64 = base64
            await MainActor.run { self.project = updated }
        } catch {
            setError("Failed to update poster: \(error.localizedDescription)")
        }
    }

    func pushAllCommits() async {
        let unsynced = localCommits.filter { !$0.isPushed }
        guard !unsynced.isEmpty else { return }

        setLoading(true)
        defer { Task { setLoading(false) } }

        var remaining = unsynced
        while !remaining.isEmpty {
            let localCommit = remaining.removeFirst()
            do {
                let newVersion = try await syncService.pushCommit(localCommit, branchID: currentBranchID)
                var state = stateStore.syncState(for: project.id)
                state.lastPulledVersionID = newVersion.id
                state.lastCommittedID = localCommit.commit.id
                stateStore.saveSyncState(state)

                if let idx = localCommits.firstIndex(where: { $0.id == localCommit.id }) {
                    localCommits[idx].isPushed = true
                }
                try? FileManager.default.removeItem(at: localCommit.cachedFolderURL)
                localCommitStore.saveLocalCommits(localCommits, for: project.id)

                await loadVersionHistory()
                await loadFiles()
            } catch SyncError.outdatedCommit {
                do {
                    let newBase = try await branchRepository.fetchHeadVersionID(branchID: currentBranchID) ?? ""
                    let rebased = try await syncService.rebaseCommit(localCommit, onto: newBase)
                    if let idx = localCommits.firstIndex(where: { $0.id == localCommit.id }) {
                        localCommits[idx] = rebased
                    }
                    localCommitStore.saveLocalCommits(localCommits, for: project.id)
                    remaining.insert(rebased, at: 0)
                } catch {
                    setError("Rebase failed: \(error.localizedDescription)")
                    return
                }
            } catch {
                setError("Push failed: \(error.localizedDescription)")
                return
            }
        }
        setError("All commits pushed successfully!")
    }

    func refreshFileTree() {
        Task { await loadFiles() }
    }

    // MARK: - Helpers
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

// MARK: - Extensions
extension NSImage {
    func jpegRepresentation(compression: CGFloat) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compression])
    }
}
