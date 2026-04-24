//
//  WorkspaceViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import AppKit
import Combine
import Foundation

protocol WorkspaceViewModelProtocol: ObservableObject, WorkspaceProjectCreating {
    var projects: [Project] { get }
    var bands: [Band] { get }
    var sections: [WorkspaceBandSection] { get }
    var visibleSections: [WorkspaceBandSection] { get }
    var searchText: String { get set }
    var isLoading: Bool { get }
    var isCreatingProject: Bool { get }

    func loadWorkspaceIfNeeded() async
    func loadWorkspace() async
    func deleteProject(_ item: WorkspaceProjectItem) async
    func pullProject(_ project: Project) async
    func commitProjectChanges(_ project: Project) async
    func getLocalState(for project: Project) -> ProjectSyncState
}

@MainActor
final class WorkspaceViewModel: WorkspaceViewModelProtocol {
    private let authService: any AuthenticatedUserProviding
    private let workspaceCatalogService: WorkspaceProjectCatalogProviding
    private let projectCreation: ProjectCreationServiceProtocol
    private let projectDeletionService: ProjectDeletionServiceProtocol
    private let syncService: ProjectSyncService
    private let stateStore: ProjectStateStore

    @Published private(set) var projects: [Project] = []
    @Published private(set) var bands: [Band] = []
    @Published private(set) var sections: [WorkspaceBandSection] = []
    @Published var searchText = ""
    @Published private var activityState: WorkspaceActivityState = .idle
    @Published var errorMessage: String?
    @Published private var hasLoadedWorkspace = false

    var isLoading: Bool { activityState.isLoading }
    var isCreatingProject: Bool { activityState.isCreatingProject }
    var hasProjects: Bool { !projects.isEmpty }
    var projectCountLabel: String { "\(projects.count) project\(projects.count == 1 ? "" : "s")" }
    var bandCountLabel: String { "\(bands.count) band\(bands.count == 1 ? "" : "s")" }
    var blockingActivityMessage: String? { activityState.overlayMessage }
    var searchResultsAreEmpty: Bool { hasProjects && visibleSections.isEmpty }

    var visibleSections: [WorkspaceBandSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sections }

        return sections.compactMap { section in
            let filteredProjects = section.projects.filter { $0.matchesSearch(query) }
            guard !filteredProjects.isEmpty else { return nil }

            return WorkspaceBandSection(
                id: section.id,
                title: section.title,
                subtitle: "\(filteredProjects.count) project\(filteredProjects.count == 1 ? "" : "s")",
                projects: filteredProjects
            )
        }
    }

    private var currentUserID: String? { authService.currentUser?.id }

    init(
        authService: any AuthenticatedUserProviding,
        workspaceCatalogService: WorkspaceProjectCatalogProviding,
        projectCreation: ProjectCreationServiceProtocol,
        projectDeletionService: ProjectDeletionServiceProtocol,
        syncService: ProjectSyncService,
        stateStore: ProjectStateStore
    ) {
        self.authService = authService
        self.workspaceCatalogService = workspaceCatalogService
        self.projectCreation = projectCreation
        self.projectDeletionService = projectDeletionService
        self.syncService = syncService
        self.stateStore = stateStore
    }

    func loadWorkspaceIfNeeded() async {
        guard !hasLoadedWorkspace else { return }
        await loadWorkspace()
    }

    func loadWorkspace() async {
        guard let userID = currentUserID else {
            finishWithError("User not logged in")
            return
        }

        await runActivity(.loading(message: "Loading workspace...")) {
            try await reloadCatalog(for: userID)
        } onError: { $0.localizedDescription }
    }

    func createProject(_ input: CreateProjectInput) async {
        guard !isCreatingProject else { return }
        guard let userID = currentUserID else {
            finishWithError("User not logged in")
            return
        }

        await runActivity(.creating(message: "Creating project...")) {
            _ = try await projectCreation.createProject(
                input,
                userID: userID,
                existingProjects: projects
            )
            try await reloadCatalog(for: userID)
        } onError: { $0.localizedDescription }
    }

    func deleteProject(_ item: WorkspaceProjectItem) async {
        guard item.canDelete else {
            finishWithError("Only the project creator or band admin can delete this project.")
            return
        }

        guard let userID = currentUserID else {
            finishWithError("User not logged in")
            return
        }

        await runActivity(.deleting(message: "Deleting project...")) {
            try await projectDeletionService.deleteProject(item.project)
            try await reloadCatalog(for: userID)
        } onError: { "Delete failed: \($0.localizedDescription)" }
    }

    func pullProject(_ project: Project) async {
        guard let userID = currentUserID else {
            finishWithError("User not logged in")
            return
        }

        let branchID = project.currentBranchID
        guard !branchID.isEmpty else {
            finishWithError("No branch selected")
            return
        }

        await runActivity(.loading(message: "Pulling latest changes...")) {
            _ = try await syncService.pull(projectID: project.id, branchID: branchID)
            try await reloadCatalog(for: userID)
        } onError: { "Pull failed: \($0.localizedDescription)" }
    }

    func commitProjectChanges(_ project: Project) async {
        guard let userID = currentUserID else {
            finishWithError("User not logged in")
            return
        }

        let branchID = project.currentBranchID
        guard !branchID.isEmpty else {
            finishWithError("No branch selected")
            return
        }

        await runActivity(.loading(message: "Committing changes...")) {
            let commit = try await syncService.createCommit(
                projectID: project.id,
                branchID: branchID,
                stagedFiles: [],
                userID: userID,
                message: "Auto-commit from workspace"
            )

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

            try await reloadCatalog(for: userID)
        } onError: { "Commit failed: \($0.localizedDescription)" }
    }

    func getLocalState(for project: Project) -> ProjectSyncState {
        stateStore.syncState(for: project.id)
    }

    func clearError() {
        errorMessage = nil
    }
}

private extension WorkspaceViewModel {
    func localCacheFolder(for projectID: String) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let base = appSupport.appendingPathComponent("StemHub/Commits/\(projectID)", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    func reloadCatalog(for userID: String) async throws {
        let catalog = try await workspaceCatalogService.loadCatalog(for: userID)
        apply(catalog)
    }

    func apply(_ catalog: WorkspaceProjectCatalog) {
        projects = catalog.snapshot.projects
        bands = catalog.snapshot.bands
        sections = catalog.sections
        errorMessage = nil
        hasLoadedWorkspace = true
        activityState = .idle
    }

    func runActivity(
        _ activity: WorkspaceActivityState,
        operation: () async throws -> Void,
        onError: (Error) -> String
    ) async {
        activityState = activity
        errorMessage = nil

        do {
            try await operation()
        } catch {
            finishWithError(onError(error))
        }
    }

    func finishWithError(_ message: String) {
        errorMessage = message
        activityState = .idle
    }
}
