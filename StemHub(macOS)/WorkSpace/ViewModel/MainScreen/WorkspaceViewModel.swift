//
//  WorkspaceViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Combine
import Foundation
import SwiftUI
import FirebaseFirestore

protocol WorkspaceViewModelProtocol: ObservableObject {
    var authService: AuthServiceProtocol { get}
    var projects: [Project] { get }
    var bands: [Band] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isCreatingProject: Bool { get }
    var isLoadingMessage: String { get }
    
    func loadProjects() async
    func createProject(name: String, folderURL: URL?, band: Band?, poster: NSImage?) async
    func pullProject(_ project: Project) async
    func commitProjectChanges(_ project: Project) async
    func getLocalState(for project: Project) -> LocalProjectState
}

final class WorkspaceViewModel: WorkspaceViewModelProtocol {
    
    // MARK: - Dependencies (all injected)
    let authService: AuthServiceProtocol
    private let persistenceStrategy: ProjectPersistenceStrategy
    private let networkStrategy: ProjectNetworkStrategy
    private let syncStrategy: ProjectSyncService
    private let bookmarkStrategy: BookmarkStrategy
    
    // MARK: - Computed user ID (single source of truth)
    var currentUserID: String? { authService.currentUser?.id }
    
    // MARK: - UI State
    @Published var projects: [Project] = []
    @Published var bands: [Band] = []
    @Published var isLoading = false
    @Published var isLoadingMessage = "Loading..."
    @Published var errorMessage: String?
    @Published var isCreatingProject = false
    
    
    // MARK: - Init
    init(
        authService: AuthServiceProtocol,
        persistenceStrategy: ProjectPersistenceStrategy = DefaultProjectPersistenceStrategy(),
        networkStrategy: ProjectNetworkStrategy = DefaultProjectNetworkStrategy(),
        syncStrategy: ProjectSyncService = DefaultProjectSyncService(),
        bookmarkStrategy: BookmarkStrategy = DefaultBookmarkStrategy()
    ) {
        self.authService = authService
        self.persistenceStrategy = persistenceStrategy
        self.networkStrategy = networkStrategy
        self.syncStrategy = syncStrategy
        self.bookmarkStrategy = bookmarkStrategy
        
        Task { await loadProjects() }
    }
    
    
    func loadProjects() async {
        setLoading(true)
        defer { Task { setLoading(false) } }
        
        guard let userID = getValidatedUserID() else { return }
        
        do {
            async let fetchedBands = networkStrategy.fetchBands(for: userID)
            async let fetchedProjects = networkStrategy.fetchAllProjects(for: userID)
            let (bandsResult, projectsResult) = try await (fetchedBands, fetchedProjects)
            
            await MainActor.run {
                self.bands = bandsResult
                self.projects = projectsResult
            }
            await migratePostersToBase64()
        } catch {
            setError(error.localizedDescription)
        }
    }
    
    func migratePostersToBase64() async {
        for project in projects where project.posterURL != nil && project.posterBase64 == nil {
            guard let url = URL(string: project.posterURL!),
                  let data = try? Data(contentsOf: url),
                  let image = NSImage(data: data) else { continue }
            
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else { continue }
            
            let base64 = jpegData.base64EncodedString()
            
            do {
                try await networkStrategy.getFirestore()
                    .collection("projects")
                    .document(project.id)
                    .updateData(["posterBase64": base64])
                print("✅ Migrated poster for project \(project.name)")
                
                await MainActor.run {
                    if let index = projects.firstIndex(where: { $0.id == project.id }) {
                        var updatedProject = projects[index]
                        updatedProject.posterBase64 = base64
                        projects[index] = updatedProject
                    }
                }
            } catch {
                print(" Migration failed for \(project.name): \(error)")
            }
        }
    }
    
    func createProject(name: String, folderURL: URL?, band: Band?, poster: NSImage?) async {
        guard !isCreatingProject else {
            setError("Already creating a project, please wait.")
            return
        }
        guard let folderURL = folderURL, let currentUserID = currentUserID else {
             setError("Missing folder or user not logged in")
            return
        }
        
         setCreating(true, message: "Creating project...")
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let targetBand = try await resolveBand(trimmedName, band: band, userID: currentUserID)
            
            let (project, projectState) = try await networkStrategy.createProject(
                name: trimmedName,
                bandID: targetBand.id,
                localFolderURL: folderURL,
                userID: currentUserID
            )
            
            if let branchID = projectState.currentBranchID, !branchID.isEmpty {
                persistenceStrategy.setCurrentBranchID(branchID, for: project.id)
            }
            
            try saveBookmarkAndPath(folderURL, for: project.id)
            
            var finalProject = project
            if let poster = poster {
                finalProject = try await attachPoster(poster, to: project)
            }
            
            await MainActor.run {
                projects.append(finalProject)
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
        
        let localPath = persistenceStrategy.getLocalPath(for: project.id)
        var state = LocalProjectState(
            projectID: project.id,
            localPath: localPath,
            lastPulledVersionID: nil,
            lastCommittedID: nil,
            currentBranchID: branchID
        )
        
        do {
            state = try await networkStrategy.pullProject(
                projectID: project.id,
                branchID: branchID,
                localRootURL: URL(fileURLWithPath: state.localPath),
                state: state
            )
            persistenceStrategy.setLastPulledVersionID(state.lastPulledVersionID, for: project.id)
        } catch {
            setError(error.localizedDescription)
        }
    }
    
    func commitProjectChanges(_ project: Project) async {
        let projectId = project.id
        let branchID = project.currentBranchID
        guard validateBranch(branchID) else { return }
        guard let currentUserID = getValidatedUserID() else { return }
        let localPath = persistenceStrategy.getLocalPath(for: project.id)
        let lastPulled = persistenceStrategy.getLastPulledVersionID(for: project.id)
        
        let state = LocalProjectState(
            projectID: projectId,
            localPath: localPath,
            lastPulledVersionID: lastPulled,
            lastCommittedID: nil,
            currentBranchID: branchID
        )
        
        do {
            let commit = try await syncStrategy.createCommit(
                projectID: project.id,
                branchID: branchID,
                localPath: localPath,
                lastPulledVersionID: lastPulled,
                files: [],
                userID: currentUserID,
                message: "Commit from UI"
            )
            
            _ = try await networkStrategy.pushCommit(commit, localRootURL: URL(fileURLWithPath: state.localPath), branchID: branchID)
        } catch {
            setError(error.localizedDescription)
        }
    }
    
    func getLocalState(for project: Project) -> LocalProjectState {
        LocalProjectState(
            projectID: project.id,
            localPath: persistenceStrategy.getLocalPath(for: project.id),
            lastPulledVersionID: persistenceStrategy.getLastPulledVersionID(for: project.id),
            lastCommittedID: nil,
            currentBranchID: project.currentBranchID
        )
    }
}

// MARK: - Logic Helpers
private extension WorkspaceViewModel {
    private func getValidatedUserID() -> String? {
        guard let userID = currentUserID else {
            setError("User not logged in")
            return nil
        }
        return userID
    }
    
    private func validateBranch(_ branchID: String) -> Bool {
        guard !branchID.isEmpty else {
            setError("Missing branch")
            return false
        }
        return true
    }
    
    private func resolveBand(_ name: String, band: Band?, userID: String) async throws -> Band {
        if let existingBand = band {
            if projects.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame && $0.bandID == existingBand.id }) {
                throw ProjectError.duplicateName
            }
            let exists = try await networkStrategy.checkDuplicateProject(name: name, bandID: existingBand.id)
            if exists { throw ProjectError.duplicateName }
            return existingBand
        } else {
            let newBand = try await networkStrategy.createBand(name: "\(name) Band", userID: userID)
            try await networkStrategy.addBand(to: userID, bandID: newBand.id)
            return newBand
        }
    }
    
    private func saveBookmarkAndPath(_ folderURL: URL, for projectID: String) throws {
        do {
            let bookmarkData = try bookmarkStrategy.createBookmark(for: folderURL)
            persistenceStrategy.storeBookmark(data: bookmarkData, for: projectID)
            print("Bookmark saved for \(folderURL.path)")
        } catch {
            print(" Bookmark failed: \(error)")
        }
        persistenceStrategy.setLocalPath(folderURL.path, for: projectID)
    }
    
    private func attachPoster(_ poster: NSImage, to project: Project) async throws -> Project {
        guard let tiffData = poster.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            return project
        }
        let base64 = jpegData.base64EncodedString()
        try await networkStrategy.getFirestore()
            .collection("projects")
            .document(project.id)
            .updateData(["posterBase64": base64])
        var updated = project
        updated.posterBase64 = base64
        return updated
    }
}

// MARK: - UI Helpers
private extension WorkspaceViewModel {
    @MainActor
    private func setLoading(_ loading: Bool, message: String = "Loading...")  {
        isLoading = loading
        isLoadingMessage = message
    }
    
    @MainActor
    private func setCreating(_ creating: Bool, message: String = "") {
        isCreatingProject = creating
        if creating {
            isLoading = true
            isLoadingMessage = message
        } else {
            isLoading = false
        }
    }
    
    @MainActor
    private func setError(_ message: String)  {
        errorMessage = message
    }
}
