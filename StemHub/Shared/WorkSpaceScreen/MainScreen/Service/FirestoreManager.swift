//
//  FirestoreManager.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation

// MARK: - Strategy Instances
protocol FirestoreProjectStrategy {
    func fetchProjects(for bandID: String) async throws -> [Project]
    func fetchAllProjects(for userID: String) async throws -> [Project]
    func fetchProject(projectID: String) async throws -> Project?
    func createProject(_ project: Project) async throws
    func updateProject(_ project: Project) async throws
}

protocol FirestoreBandStrategy {
    func createBand(name: String, userID: String) async throws -> Band
    func addBand(to userID: String, bandID: String) async throws
    func fetchBands(for userID: String) async throws -> [Band]
    func fetchBand(bandID: String) async throws -> Band?
}

protocol FirestoreVersionStrategy {
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion]
    func fetchVersion(versionID: String) async throws -> ProjectVersion?
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion]
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
}

protocol FirestoreBranchStrategy {
    func createBranch(projectID: String, name: String, fromBranchID: String?, userID: String) async throws -> Branch
    func fetchBranches(for projectID: String) async throws -> [Branch]
    func fetchBranch(branchID: String) async throws -> Branch?
    func updateBranchHead(branchID: String, versionID: String) async throws
}

protocol FirestoreUserStrategy {
    func createUser(_ user: User) async throws
    func fetchUser(userID: String) async throws -> User?
    func updateUser(_ user: User) async throws
}

protocol FirestoreStorageStrategy {
//    func uploadProjectPoster(projectID: String, image: Any) async throws -> String
    func uploadProjectPoster(projectID: String, image: NSImage) async throws -> String
    func updateProjectPoster(projectID: String, posterURL: String) async throws
}

// MARK: - Concrete Strategy Implementations
struct DefaultFirestoreProjectStrategy: FirestoreProjectStrategy {
    private let db = Firestore.firestore()
    
    func fetchProjects(for bandID: String) async throws -> [Project] {
        let snapshot = try await db.collection("projects")
            .whereField("bandID", isEqualTo: bandID)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Project.self) }
    }
    
    func fetchAllProjects(for userID: String) async throws -> [Project] {
        let userDoc = try await db.collection("users").document(userID).getDocument()
        guard let user = try? userDoc.data(as: User.self) else { return [] }
        
        var allProjects: [Project] = []
        for bandID in user.bandIDs {
            let projects = try await fetchProjects(for: bandID)
            allProjects.append(contentsOf: projects)
        }
        return allProjects
    }
    
    func fetchProject(projectID: String) async throws -> Project? {
        let doc = try await db.collection("projects").document(projectID).getDocument()
        return try? doc.data(as: Project.self)
    }
    
    func createProject(_ project: Project) async throws {
        try db.collection("projects").document(project.id).setData(from: project)
    }
    
    func updateProject(_ project: Project) async throws {
        try db.collection("projects").document(project.id).setData(from: project, merge: true)
    }
}

struct DefaultFirestoreBandStrategy: FirestoreBandStrategy {
    private let db = Firestore.firestore()
    
    func createBand(name: String, userID: String) async throws -> Band {
        let band = Band(
            id: UUID().uuidString,
            name: name,
            memberIDs: [userID],
            projectIDs: [],
            createdAt: Date()
        )
        try db.collection("bands").document(band.id).setData(from: band)
        return band
    }
    
    func addBand(to userID: String, bandID: String) async throws {
        try await db.collection("users").document(userID).updateData([
            "bandIDs": FieldValue.arrayUnion([bandID])
        ])
    }
    
    func fetchBands(for userID: String) async throws -> [Band] {
        let userDoc = try await db.collection("users").document(userID).getDocument()
        guard let user = try? userDoc.data(as: User.self) else { return [] }
        
        var bands: [Band] = []
        for bandID in user.bandIDs {
            if let band = try await fetchBand(bandID: bandID) {
                bands.append(band)
            }
        }
        return bands
    }
    
    func fetchBand(bandID: String) async throws -> Band? {
        let doc = try await db.collection("bands").document(bandID).getDocument()
        return try? doc.data(as: Band.self)
    }
}

struct DefaultFirestoreVersionStrategy: FirestoreVersionStrategy {
    private let db = Firestore.firestore()
    
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        do {
            let snapshot = try await db.collection("projectVersions")
                .whereField("projectID", isEqualTo: projectID)
                .order(by: "versionNumber", descending: true)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
        } catch {
            print("⚠️ Index not ready, fetching without order")
            let snapshot = try await db.collection("projectVersions")
                .whereField("projectID", isEqualTo: projectID)
                .getDocuments()
            var versions = snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
            versions.sort { $0.versionNumber > $1.versionNumber }
            return versions
        }
    }
    
    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        guard !versionID.isEmpty else { return nil }
        let doc = try await db.collection("projectVersions").document(versionID).getDocument()
        return try? doc.data(as: ProjectVersion.self)
    }
    
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion] {
        var fileVersions: [FileVersion] = []
        for id in fileVersionIDs where !id.isEmpty {
            do {
                let doc = try await db.collection("fileVersions").document(id).getDocument()
                if let fv = try? doc.data(as: FileVersion.self) {
                    fileVersions.append(fv)
                }
            } catch {
                print("Failed to fetch file version \(id): \(error)")
            }
        }
        return fileVersions
    }
    
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        guard !versionID.isEmpty else { return [] }
        
        let versionDoc = try await db.collection("projectVersions").document(versionID).getDocument()
        guard versionDoc.exists else { return [] }
        
        let projectVersion = try versionDoc.data(as: ProjectVersion.self)
        
        var snapshots: [RemoteFileSnapshot] = []
        for fileVersionID in projectVersion.fileVersionIDs {
            guard !fileVersionID.isEmpty else { continue }
            
            let fvDoc = try await db.collection("fileVersions").document(fileVersionID).getDocument()
            guard fvDoc.exists else { continue }
            
            let fv = try fvDoc.data(as: FileVersion.self)
            snapshots.append(RemoteFileSnapshot(
                fileID: fv.fileID,
                path: fv.path,
                hash: fv.blobID,
                versionID: projectVersion.id
            ))
        }
        return snapshots
    }
}

struct DefaultFirestoreBranchStrategy: FirestoreBranchStrategy {
    private let db = Firestore.firestore()
    
    func createBranch(projectID: String, name: String, fromBranchID: String?, userID: String) async throws -> Branch {
        let branch = Branch(
            id: UUID().uuidString,
            projectID: projectID,
            name: name,
            headVersionID: nil,
            createdAt: Date(),
            createdBy: userID
        )
        try db.collection("branches").document(branch.id).setData(from: branch)
        
        if let fromBranchID = fromBranchID {
            let fromBranchDoc = try await db.collection("branches").document(fromBranchID).getDocument()
            let fromBranch = try fromBranchDoc.data(as: Branch.self)
            if let headVersionID = fromBranch.headVersionID {
                try await updateBranchHead(branchID: branch.id, versionID: headVersionID)
            }
        }
        
        return branch
    }
    
    func fetchBranches(for projectID: String) async throws -> [Branch] {
        let snapshot = try await db.collection("branches")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Branch.self) }
    }
    
    func fetchBranch(branchID: String) async throws -> Branch? {
        let doc = try await db.collection("branches").document(branchID).getDocument()
        return try? doc.data(as: Branch.self)
    }
    
    func updateBranchHead(branchID: String, versionID: String) async throws {
        try await db.collection("branches").document(branchID).updateData([
            "headVersionID": versionID
        ])
    }
}

struct DefaultFirestoreUserStrategy: FirestoreUserStrategy {
    private let db = Firestore.firestore()
    
    func createUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }
    
    func fetchUser(userID: String) async throws -> User? {
        let doc = try await db.collection("users").document(userID).getDocument()
        return try? doc.data(as: User.self)
    }
    
    func updateUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user, merge: true)
    }
}

struct DefaultFirestoreStorageStrategy: FirestoreStorageStrategy {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    #if os(macOS)

    func uploadProjectPoster(projectID: String, image: NSImage) async throws -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(projectID)_\(timestamp).png"
        let storageRef = Storage.storage().reference().child("projectPosters/\(fileName)")
        
        guard let data = image.tiffRepresentation,
              let pngData = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "ImageConversion", code: -1)
        }
        
        // Direct upload – no delete, no metadata check
        _ = try await storageRef.putDataAsync(pngData)
        let url = try await storageRef.downloadURL()
        
        // Update the project with this new URL
        try await db.collection("projects").document(projectID).updateData([
            "posterURL": url.absoluteString
        ])
        
        return url.absoluteString
    }
    #endif
    
    #if os(iOS)
    func uploadProjectPoster(projectID: String, image: Any) async throws -> String {
        guard let uiImage = image as? UIImage,
              let pngData = uiImage.pngData() else {
            throw NSError(domain: "Image conversion failed", code: -1)
        }
        
        let storageRef = storage.reference().child("projectPosters/\(projectID).png")
        _ = try await storageRef.putDataAsync(pngData)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
    #endif
    
    func updateProjectPoster(projectID: String, posterURL: String) async throws {
        try await db.collection("projects").document(projectID).updateData([
            "posterURL": posterURL
        ])
    }
}

// MARK: - Main Firestore Manager
final class FirestoreManager {
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    private let syncOrchestrator: SyncOrchestrator
    
    // Strategy instances - can be swapped for testing
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
    
    func updateProjectPoster(projectID: String, posterURL: String) async throws {
        try await storageStrategy.updateProjectPoster(projectID: projectID, posterURL: posterURL)
    }
    
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
