
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

@MainActor
final class WorkspaceViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var isLoadingMessage: String = "Loading..."
    @Published var projects: [Project] = []
    @Published var bands: [Band] = []
    @Published var isCreatingProject = false
    @Published var errorMessage: String?
    
    private let firestore = FirestoreManager.shared
    
    @Published var currentUser: User? {
        didSet {
            Task { await loadProjects() }
        }
    }
    
    init(currentUser: User?) {
        self.currentUser = currentUser
        Task { await loadProjects() }
    }
    
    func loadProjects() async {
        guard let currentUser = currentUser else {
            self.projects = []
            self.bands = []
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch bands
            var userBands: [Band] = []
            for bandID in currentUser.bandIDs {
                let bandDoc = try await firestore.firestore().collection("bands").document(bandID).getDocument()
                if let band = try? bandDoc.data(as: Band.self) {
                    userBands.append(band)
                }
            }
            self.bands = userBands
            
            // Fetch projects using the new method
            self.projects = try await firestore.fetchAllProjects(for: currentUser.id)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
#if os(macOS)
    func createProject(name: String, folderURL: URL?, band: Band?, poster: NSImage?) async {
        guard let folderURL = folderURL, let currentUser = currentUser else { return }
        
        await MainActor.run {
            isLoading = true
            isLoadingMessage = "Creating project..."
        }
        
        do {
            var targetBand: Band
            
            if let existingBand = band {
                targetBand = existingBand
            } else {
                // Create new band
                targetBand = try await firestore.createBand(
                    name: "\(name) Band",
                    userID: currentUser.id
                )
                try await firestore.addBand(to: currentUser.id, bandID: targetBand.id)
            }
            
            // Upload poster if exists
            var posterURL: String? = nil
            if let poster = poster {
                posterURL = try await firestore.uploadProjectPoster(projectID: targetBand.id, image: poster)
            }
            
            // Create project with full branch support
            let (project, _) = try await firestore.createProject(
                name: name,
                bandID: targetBand.id,
                localFolderURL: folderURL,
                userID: currentUser.id
            )
            
            storeBookmark(for: folderURL, projectID: project.id)
            UserDefaults.standard.set(folderURL.path, forKey: "project_\(project.id)_path")
            
            // Update poster URL if uploaded
            if let posterURL = posterURL {
                try await firestore.firestore().collection("projects").document(project.id).updateData([
                    "posterURL": posterURL
                ])
                var updatedProject = project
                updatedProject.posterURL = posterURL
                projects.append(updatedProject)
            } else {
                projects.append(project)
            }
            
            UserDefaults.standard.set(folderURL.path, forKey: "project_\(project.id)_path")
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
#endif
    
    func pullProject(_ project: Project) async {
        do {
            let branchID = project.currentBranchID
            guard !branchID.isEmpty else { return }
            
            // Get local path from UserDefaults
            let localPath = UserDefaults.standard.string(forKey: "project_\(project.id)_path") ?? "/path/to/local"
            
            var state = LocalProjectState(
                projectID: project.id,
                localPath: localPath,
                lastPulledVersionID: nil,
                lastCommittedID: nil,
                currentBranchID: branchID
            )
            
            state = try await firestore.pullProject(
                projectID: project.id,
                branchID: branchID,
                localRootURL: URL(fileURLWithPath: state.localPath),
                state: state
            )
            
            // Save updated state
            UserDefaults.standard.set(state.lastPulledVersionID, forKey: "project_\(project.id)_lastPulled")
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func commitProjectChanges(_ project: Project) async {
        guard let currentUser = currentUser else { return }
        
        do {
            let branchID = project.currentBranchID
            guard !branchID.isEmpty else { return }
            
            let localPath = UserDefaults.standard.string(forKey: "project_\(project.id)_path") ?? "/path/to/local"
            
            let state = LocalProjectState(
                projectID: project.id,
                localPath: localPath,
                lastPulledVersionID: UserDefaults.standard.string(forKey: "project_\(project.id)_lastPulled"),
                lastCommittedID: nil,
                currentBranchID: branchID
            )
            
            // Use SyncOrchestrator instead of SyncEngine
            let syncOrchestrator = SyncOrchestrator()
            let scanner = LocalFileScanner() // Use new scanner
            
            let localFiles = try scanner.scan(folderURL: URL(fileURLWithPath: state.localPath))
            print("local files: \(localFiles)")
            
            var remoteSnapshot: [RemoteFileSnapshot] = []
            if let lastPulled = state.lastPulledVersionID {
                remoteSnapshot = try await firestore.fetchRemoteSnapshot(versionID: lastPulled)
            }
            
            let commit = try await syncOrchestrator.commit(
                localPath: URL(fileURLWithPath: state.localPath),
                localState: state,
                remoteSnapshot: remoteSnapshot,
                userID: currentUser.id,
                message: "Commit from UI"
            )
            
            let _ = try await firestore.pushCommit(
                commit,
                localRootURL: URL(fileURLWithPath: state.localPath),
                branchID: branchID
            )
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getLocalState(for project: Project) -> LocalProjectState {
        let localPath = UserDefaults.standard.string(forKey: "project_\(project.id)_path") ?? ""
        return LocalProjectState(
            projectID: project.id,
            localPath: localPath,
            lastPulledVersionID: UserDefaults.standard.string(forKey: "project_\(project.id)_lastPulled"),
            lastCommittedID: nil,
            currentBranchID: project.currentBranchID
        )
    }
    
    func storeBookmark(for folderURL: URL, projectID: String) {
        do {
            let bookmarkData = try folderURL.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "project_\(projectID)_bookmark")
        } catch {
            print("Failed to create bookmark: \(error)")
            errorMessage = "Could not save folder access permission."
        }
    }
}
