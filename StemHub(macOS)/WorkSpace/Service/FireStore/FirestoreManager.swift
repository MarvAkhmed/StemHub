//
//  FirestoreManager.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation

final class FirestoreManager {
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    private let syncOrchestrator: SyncOrchestrator
    
    var projectStrategy: FirestoreProjectStrategy = DefaultFirestoreProjectStrategy()
    var bandStrategy: FirestoreBandStrategy = DefaultFirestoreBandStrategy()
    var versionStrategy: FirestoreVersionStrategy = DefaultFirestoreVersionStrategy()
    var branchStrategy: FirestoreBranchStrategy = DefaultFirestoreBranchStrategy()
    var userStrategy: FirestoreUserStrategy = DefaultFirestoreUserStrategy()
    var storageStrategy: FirestoreStorageStrategy = DefaultFirestoreStorageStrategy()
    
    private init() {
        self.syncOrchestrator = SyncOrchestrator()
    }
    
    func firestore() -> Firestore { return db }
    
    // MARK: - Project Operations
    func fetchProjects(for bandID: String) async throws -> [Project] {
        return try await projectStrategy.fetchProjects(for: bandID)
    }
    
    func fetchAllProjects(for userID: String) async throws -> [Project] {
        return try await projectStrategy.fetchAllProjects(for: userID)
    }
    
    func fetchProject(projectID: String) async throws -> Project? {
        return try await projectStrategy.fetchProject(projectID: projectID)
    }
    
    // MARK: - Band Operations
    func createBand(name: String, userID: String) async throws -> Band {
        return try await bandStrategy.createBand(name: name, userID: userID)
    }
    
    func addBand(to userID: String, bandID: String) async throws {
        try await bandStrategy.addBand(to: userID, bandID: bandID)
    }
    
    func fetchBands(for userID: String) async throws -> [Band] {
        return try await bandStrategy.fetchBands(for: userID)
    }
    
    // MARK: - Version Operations
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        return try await versionStrategy.fetchVersionHistory(projectID: projectID)
    }
    
    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        return try await versionStrategy.fetchVersion(versionID: versionID)
    }
    
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion] {
        return try await versionStrategy.fetchFileVersions(fileVersionIDs: fileVersionIDs)
    }
    
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        return try await versionStrategy.fetchRemoteSnapshot(versionID: versionID)
    }
    
    // MARK: - Branch Operations
    func createBranch(projectID: String, name: String, fromBranchID: String? = nil, userID: String) async throws -> Branch {
        return try await branchStrategy.createBranch(projectID: projectID, name: name, fromBranchID: fromBranchID, userID: userID)
    }
    
    func fetchBranches(for projectID: String) async throws -> [Branch] {
        return try await branchStrategy.fetchBranches(for: projectID)
    }
    
    func fetchBranch(branchID: String) async throws -> Branch? {
        return try await branchStrategy.fetchBranch(branchID: branchID)
    }
    
    // MARK: - User Operations
    func createUser(_ user: User) async throws {
        try await userStrategy.createUser(user)
    }
    
    func fetchUser(userID: String) async throws -> User? {
        return try await userStrategy.fetchUser(userID: userID)
    }
    
    // MARK: - Storage Operations
    #if os(macOS)
    func uploadProjectPoster(projectID: String, image: NSImage) async throws -> String {
        return try await storageStrategy.uploadProjectPoster(projectID: projectID, image: image)
    }
    #endif
    
    #if os(iOS)
    func uploadProjectPoster(projectID: String, image: UIImage) async throws -> String {
        return try await storageStrategy.uploadProjectPoster(projectID: projectID, image: image)
    }
    #endif
    
//    func updateProjectPoster(projectID: String, posterURL: String) async throws {
//        return try await storageStrategy.updateProjectPoster(projectID: projectID, posterURL: posterURL)
//    }
    
    // MARK: - Project & Branch Creation (Complex Operations)
    func createProject(name: String, bandID: String, localFolderURL: URL, userID: String) async throws -> (Project, LocalProjectState) {
        let projectID = UUID().uuidString
        let project = Project(
            id: projectID,
            name: name,
            posterURL: nil,
            bandID: bandID,
            createdBy: userID,
            currentBranchID: "",
            currentVersionID: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await projectStrategy.createProject(project)
        
        let branch = try await branchStrategy.createBranch(
            projectID: project.id,
            name: "main",
            fromBranchID: nil,
            userID: userID
        )
        
        // Create an empty commit (no files)
        let emptyCommit = Commit(
            id: UUID().uuidString,
            projectID: project.id,
            parentCommitID: nil,
            basedOnVersionID: "",                       // no base version yet
            diff: ProjectDiff(files: []),               // empty diff
            fileSnapshot: [],                           // no files
            createdBy: userID,
            createdAt: Date(),
            message: "Initial empty commit",
            status: .pending
        )
        
        let projectVersion = try await syncOrchestrator.pushCommit(
            emptyCommit,
            localRootURL: localFolderURL,
            branchID: branch.id
        )
        
        var updatedProject = project
        updatedProject.currentBranchID = branch.id
        updatedProject.currentVersionID = projectVersion.id
        try await projectStrategy.updateProject(updatedProject)
        
        let state = LocalProjectState(
            projectID: project.id,
            localPath: localFolderURL.path,
            lastPulledVersionID: projectVersion.id,
            lastCommittedID: emptyCommit.id,
            currentBranchID: branch.id
        )
        
        return (updatedProject, state)
    }
    
    // MARK: - Pull & Push Operations
    func pullProject(projectID: String, branchID: String, localRootURL: URL, state: LocalProjectState) async throws -> LocalProjectState {
        return try await syncOrchestrator.pullProject(
            projectID: projectID,
            branchID: branchID,
            localRootURL: localRootURL,
            state: state
        )
    }
    
    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        return try await syncOrchestrator.pushCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }
}
