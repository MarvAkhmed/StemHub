//
//  WorkspaceViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Combine
import Foundation
import SwiftUI

protocol WorkspaceViewModelProtocol: ObservableObject {
    var projects: [Project] { get }
    var bands: [Band] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isCreatingProject: Bool { get }
    var isLoadingMessage: String { get }

    func loadWorkspace() async
    func createProject(name: String, folderURL: URL?, band: Band?, poster: NSImage?) async
    func pullProject(_ project: Project) async
    func commitProjectChanges(_ project: Project) async
    func getLocalState(for project: Project) -> ProjectSyncState
}

final class WorkspaceViewModel: WorkspaceViewModelProtocol {

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let workspaceLoader: WorkspaceLoaderServiceProtocol
    private let projectCreation: ProjectCreationServiceProtocol
    private let syncService: ProjectSyncService
    private let stateStore: ProjectStateStore
    private let bookmarkStrategy: BookmarkStrategy

    // MARK: - State
    @Published var projects: [Project] = []
    @Published var bands: [Band] = []
    @Published var isLoading = false
    @Published var isLoadingMessage = "Loading..."
    @Published var errorMessage: String?
    @Published var isCreatingProject = false

    private var currentUserID: String? { authService.currentUser?.id }

    // MARK: - Init
    init(
        authService: AuthServiceProtocol,
        workspaceLoader: WorkspaceLoaderServiceProtocol = WorkspaceLoaderService(),
        projectCreation: ProjectCreationServiceProtocol = ProjectCreationService(),
        syncService: ProjectSyncService = DefaultProjectSyncService(),
        stateStore: ProjectStateStore = UserDefaultsProjectStateStore(),
        bookmarkStrategy: BookmarkStrategy = DefaultBookmarkStrategy()
    ) {
        self.authService = authService
        self.workspaceLoader = workspaceLoader
        self.projectCreation = projectCreation
        self.syncService = syncService
        self.stateStore = stateStore
        self.bookmarkStrategy = bookmarkStrategy

        Task { await loadWorkspace() }
    }

    // MARK: - Public Methods
    func loadWorkspace() async {
        setLoading(true)
        defer { Task { setLoading(false) } }

        guard let userID = currentUserID else {
            setError("User not logged in")
            return
        }

        do {
            let snapshot = try await workspaceLoader.loadWorkspace(for: userID)
            await MainActor.run {
                self.bands = snapshot.bands
                self.projects = snapshot.projects
            }
        } catch {
            setError(error.localizedDescription)
        }
    }

    func createProject(name: String, folderURL: URL?, band: Band?, poster: NSImage?) async {
        guard !isCreatingProject else { return }
        guard let folderURL = folderURL, let userID = currentUserID else {
            setError("Missing folder or user not logged in")
            return
        }

        setCreating(true, message: "Creating project...")

        let input = CreateProjectInput(
            name: name,
            folderURL: folderURL,
            selectedBand: band,
            poster: poster
        )

        do {
            let newProject = try await projectCreation.createProject(
                input,
                userID: userID,
                existingProjects: projects
            )
            await MainActor.run {
                projects.append(newProject)
            }
        } catch {
            setError(error.localizedDescription)
        }

        setCreating(false)
    }

    func pullProject(_ project: Project) async {
        let branchID = project.currentBranchID
        guard !branchID.isEmpty else {
            setError("No branch selected")
            return
        }

        setLoading(true)
        defer { Task { setLoading(false) } }

        do {
            _ = try await syncService.pull(projectID: project.id, branchID: branchID)
            // Optionally reload workspace to reflect changes
            await loadWorkspace()
        } catch {
            setError("Pull failed: \(error.localizedDescription)")
        }
    }

    func commitProjectChanges(_ project: Project) async {
        guard let userID = currentUserID else {
            setError("User not logged in")
            return
        }

        let branchID = project.currentBranchID
        guard !branchID.isEmpty else {
            setError("No branch selected")
            return
        }

        setLoading(true, message: "Committing changes...")
        defer { Task { setLoading(false) } }

        do {
            // Create a commit with all local changes (stagedFiles = nil means auto-detect)
            let commit = try await syncService.createCommit(
                projectID: project.id,
                branchID: branchID,
                stagedFiles: [],
                userID: userID,
                message: "Auto-commit from workspace"
            )
            // Push immediately
            _ = try await syncService.pushCommit(
                LocalCommit(
                    id: commit.id,
                    commit: commit,
                    cachedFolderURL: localCacheFolder(for: project.id),
                    isPushed: false,
                    createdAt: Date()
                ),
                branchID: branchID
            )
        } catch {
            setError("Commit failed: \(error.localizedDescription)")
        }
    }

    func getLocalState(for project: Project) -> ProjectSyncState {
        return stateStore.syncState(for: project.id)
    }

    // MARK: - Helpers
    private func localCacheFolder(for projectID: String) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let base = appSupport.appendingPathComponent("StemHub/Commits/\(projectID)", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    @MainActor
    private func setLoading(_ loading: Bool, message: String = "Loading...") {
        isLoading = loading
        isLoadingMessage = message
    }

    @MainActor
    private func setCreating(_ creating: Bool, message: String = "") {
        isCreatingProject = creating
        isLoading = creating
        isLoadingMessage = message
    }

    @MainActor
    private func setError(_ message: String) {
        errorMessage = message
    }
}
