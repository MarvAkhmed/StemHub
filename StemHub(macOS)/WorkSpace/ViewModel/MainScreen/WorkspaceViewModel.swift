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

final class WorkspaceViewModel: ObservableObject {
    
    @Published var projects: [Project] = []
    @Published var bands: [Band] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCreatingProject = false
    @Published var isLoadingMessage = "Loading..."
    
    private let currentUser: User
    private let persistenceStrategy: ProjectPersistenceStrategy
    private let networkStrategy: ProjectNetworkStrategy
    private let syncStrategy: ProjectSyncStrategy
    private let bookmarkStrategy: BookmarkStrategy
    var currentUserID: String { currentUser.id }
    
    init(currentUser: User,
         persistenceStrategy: ProjectPersistenceStrategy = DefaultProjectPersistenceStrategy(),
         networkStrategy: ProjectNetworkStrategy = DefaultProjectNetworkStrategy(),
         syncStrategy: ProjectSyncStrategy = DefaultProjectSyncStrategy(),
         bookmarkStrategy: BookmarkStrategy = DefaultBookmarkStrategy()) {
        self.currentUser = currentUser
        self.persistenceStrategy = persistenceStrategy
        self.networkStrategy = networkStrategy
        self.syncStrategy = syncStrategy
        self.bookmarkStrategy = bookmarkStrategy
        Task { await loadProjects() }
    }
 
    
    // MARK: - Public Methods
    
    func loadProjects() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            bands = try await networkStrategy.fetchBands(for: currentUser.id)
            projects = try await networkStrategy.fetchAllProjects(for: currentUser.id)
            await migratePostersToBase64()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
#if os(macOS)
    
    func migratePostersToBase64() async {
        for project in projects where project.posterURL != nil && project.posterBase64 == nil {
            guard let url = URL(string: project.posterURL!),
                  let data = try? Data(contentsOf: url),
                  let image = NSImage(data: data) else { continue }
            
            // Convert to base64
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else { continue }
            
            let base64 = jpegData.base64EncodedString()
            
            // Update Firestore document
            do {
                try await networkStrategy.getFirestore()
                    .collection("projects")
                    .document(project.id)
                    .updateData(["posterBase64": base64])
                print("✅ Migrated poster for project \(project.name)")
            } catch {
                print("❌ Migration failed for \(project.name): \(error)")
            }
            
            // Update local project
            var updatedProject = project
            updatedProject.posterBase64 = base64
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                await MainActor.run {
                    projects[index] = updatedProject
                }
            }
        }
    }
    
    func createProject(name: String, folderURL: URL?, band: Band?, poster: NSImage?) async {
        // 1. Prevent concurrent creation attempts
        guard !isCreatingProject else {
            errorMessage = "Already creating a project, please wait."
            return
        }
        
        guard let folderURL = folderURL else { return }
        
        await MainActor.run {
            isCreatingProject = true
            isLoading = true
            isLoadingMessage = "Creating project..."
        }
        
        // Clean the name for comparison (trim whitespace, case‑insensitive)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            var targetBand: Band
            
            if let existingBand = band {
                targetBand = existingBand
                
                if projects.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame && $0.bandID == targetBand.id }) {
                    throw ProjectError.duplicateName
                }
                
                let exists = try await networkStrategy.checkDuplicateProject(name: trimmedName, bandID: targetBand.id)
                if exists {
                    throw ProjectError.duplicateName
                }
            } else {
                targetBand = try await networkStrategy.createBand(name: "\(trimmedName) Band", userID: currentUser.id)
                try await networkStrategy.addBand(to: currentUser.id, bandID: targetBand.id)
            }
            
            // Create the project on Firestore (without poster)
            let (project, projectState) = try await networkStrategy.createProject(
                name: trimmedName,
                bandID: targetBand.id,
                localFolderURL: folderURL,
                userID: currentUser.id
            )
            
            if let branchID = projectState.currentBranchID, !branchID.isEmpty {
                persistenceStrategy.setCurrentBranchID(branchID, for: project.id)
            }
            
            // Store bookmark and local path
            do {
                
                let bookmarkData = try bookmarkStrategy.createBookmark(for: folderURL)
                persistenceStrategy.storeBookmark(data: bookmarkData, for: project.id)
                print("✅ Bookmark: \(bookmarkData)  saved for \(folderURL.path)")
            } catch {
                print("❌ Bookmark failed: \(error)")
            }
            persistenceStrategy.setLocalPath(folderURL.path, for: project.id)
            
            // Now upload the poster using the REAL project ID
            var finalProject = project
            // In createProject, after setting finalProject.posterBase64
            if let poster = poster,
               let tiffData = poster.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
                let base64 = jpegData.base64EncodedString()
                finalProject.posterBase64 = base64
                
                // ✅ Persist to Firestore
                try await networkStrategy.getFirestore()
                    .collection("projects")
                    .document(project.id)
                    .updateData(["posterBase64": base64])
            }
            
            await MainActor.run {
                projects.append(finalProject)
            }
            
        } catch let error as ProjectError {
            await MainActor.run { errorMessage = error.localizedDescription }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
        
        await MainActor.run {
            isCreatingProject = false
            isLoading = false
        }
    }
#endif
    
    func pullProject(_ project: Project) async {
        do {
            let branchID = project.currentBranchID
            guard !branchID.isEmpty else { return }
            
            let localPath = persistenceStrategy.getLocalPath(for: project.id)
            var state = LocalProjectState(
                projectID: project.id,
                localPath: localPath,
                lastPulledVersionID: nil,
                lastCommittedID: nil,
                currentBranchID: branchID
            )
            
            state = try await networkStrategy.pullProject(
                projectID: project.id,
                branchID: branchID,
                localRootURL: URL(fileURLWithPath: state.localPath),
                state: state
            )
            
            persistenceStrategy.setLastPulledVersionID(state.lastPulledVersionID, for: project.id)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func commitProjectChanges(_ project: Project) async {
        do {
            let branchID = project.currentBranchID
            guard !branchID.isEmpty else { return }
            
            let localPath = persistenceStrategy.getLocalPath(for: project.id)
            let lastPulled = persistenceStrategy.getLastPulledVersionID(for: project.id)
            
            let state = LocalProjectState(
                projectID: project.id,
                localPath: localPath,
                lastPulledVersionID: lastPulled,
                lastCommittedID: nil,
                currentBranchID: branchID
            )
            
            let scanner = LocalFileScanner()
            let localFiles = try scanner.scan(folderURL: URL(fileURLWithPath: state.localPath))
            print("local files: \(localFiles)")
            
            var remoteSnapshot: [RemoteFileSnapshot] = []
            if let lastPulled = state.lastPulledVersionID {
                remoteSnapshot = try await networkStrategy.fetchRemoteSnapshot(versionID: lastPulled)
            }
            
            let commit = try await syncStrategy.commit(
                localPath: URL(fileURLWithPath: state.localPath),
                localState: state,
                remoteSnapshot: remoteSnapshot,
                userID: currentUser.id,
                message: "Commit from UI"
            )
            
            _ = try await networkStrategy.pushCommit(commit, localRootURL: URL(fileURLWithPath: state.localPath), branchID: branchID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getLocalState(for project: Project) -> LocalProjectState {
        let localPath = persistenceStrategy.getLocalPath(for: project.id)
        return LocalProjectState(
            projectID: project.id,
            localPath: localPath,
            lastPulledVersionID: persistenceStrategy.getLastPulledVersionID(for: project.id),
            lastCommittedID: nil,
            currentBranchID: project.currentBranchID
        )
    }
}


