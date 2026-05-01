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
    private let workspaceStateService: ProjectWorkspaceStateManaging
    private let commitWorkflowService: ProjectCommitWorkflowing
    private let posterImageProvider: ProjectPosterImageProviding
    private let sectionFilter: WorkspaceSectionFiltering
    
    @Published private(set) var projects: [Project] = []
    @Published private(set) var bands: [Band] = []
    @Published private(set) var sections: [WorkspaceBandSection] = [] {
        didSet {
            rebuildVisibleSections()
        }
    }
    @Published private(set) var visibleSections: [WorkspaceBandSection] = []
    @Published var searchText = "" {
        didSet {
            rebuildVisibleSections()
        }
    }
    @Published private var activityState: WorkspaceActivityState = .idle
    @Published var errorMessage: String?
    @Published private var hasLoadedWorkspace = false

    var isLoading: Bool { activityState.isLoading }
    var isCreatingProject: Bool { activityState.isCreatingProject }
    var hasProjects: Bool { !projects.isEmpty }
    var projectCountLabel: String { sectionFilter.projectCountLabel(for: projects.count) }
    var bandCountLabel: String { sectionFilter.bandCountLabel(for: bands.count) }
    var blockingActivityMessage: String? { activityState.overlayMessage }
    var searchResultsAreEmpty: Bool { hasProjects && visibleSections.isEmpty }

    private var currentUserID: String? { authService.currentUser?.id }

    init(
        authService: any AuthenticatedUserProviding,
        workspaceCatalogService: WorkspaceProjectCatalogProviding,
        projectCreation: ProjectCreationServiceProtocol,
        projectDeletionService: ProjectDeletionServiceProtocol,
        syncService: ProjectSyncService,
        workspaceStateService: ProjectWorkspaceStateManaging,
        commitWorkflowService: ProjectCommitWorkflowing,
        sectionFilter: WorkspaceSectionFiltering,
        posterImageProvider: ProjectPosterImageProviding
    ) {
        self.authService = authService
        self.workspaceCatalogService = workspaceCatalogService
        self.projectCreation = projectCreation
        self.projectDeletionService = projectDeletionService
        self.syncService = syncService
        self.workspaceStateService = workspaceStateService
        self.commitWorkflowService = commitWorkflowService
        self.posterImageProvider = posterImageProvider
        self.sectionFilter = sectionFilter
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
            _ = try await projectCreation.createProject(input, userID: userID, existingProjects: projects
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
            let commit = try await commitWorkflowService.createCommitDraft(
                projectID: project.id,
                branchID: branchID,
                stagedFiles: [],
                userID: userID,
                message: "Auto-commit from workspace"
            )

            _ = try await commitWorkflowService.stageCommit(
                commit,
                projectID: project.id,
                branchID: branchID
            )
            _ = try await commitWorkflowService.pushAllCommits(
                projectID: project.id,
                branchID: branchID
            )

            try await reloadCatalog(for: userID)
        } onError: { "Commit failed: \($0.localizedDescription)" }
    }

    func getLocalState(for project: Project) -> ProjectSyncState {
        workspaceStateService.state(for: project.id)
    }

    func makeProjectCardViewModel(for item: WorkspaceProjectItem) -> ProjectCardViewModel {
        ProjectCardViewModel(
            item: item,
            posterImageProvider: posterImageProvider
        )
    }

    func clearError() {
        errorMessage = nil
    }
}

private extension WorkspaceViewModel {

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

    func rebuildVisibleSections() {
        visibleSections = sectionFilter.visibleSections(
            from: sections,
            query: searchText
        )
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
