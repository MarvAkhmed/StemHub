//  DefaultProjectNetworkService.swift
//  StemHub
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import FirebaseFirestore

final class ProjectNetworkService: ProjectNetworkStrategy {
    
    private let firestore: FirestoreManager
    
    init(firestore: FirestoreManager = .shared) {
        self.firestore = firestore
    }
    
    
    // MARK: - Bands
    
    func fetchBands(for userID: String) async throws -> [Band] {
        var bands: [Band] = []
        let userDoc = try await firestore.firestore().collection("users").document(userID).getDocument()
        guard let bandIDs = userDoc.data()?["bandIDs"] as? [String] else {
            return []
        }
        for bandID in bandIDs {
            let bandDoc = try await firestore.firestore().collection("bands").document(bandID).getDocument()
            if let band = try? bandDoc.data(as: Band.self) {
                bands.append(band)
            }
        }
        return bands
    }
    
    func createBand(name: String, userID: String) async throws -> Band {
        try await firestore.createBand(name: name, userID: userID)
    }
    
    func addBand(to userID: String, bandID: String) async throws {
        try await firestore.addBand(to: userID, bandID: bandID)
    }
    
    // MARK: - Projects
    
    func fetchAllProjects(for userID: String) async throws -> [Project] {
        try await firestore.fetchAllProjects(for: userID)
    }
    
    func createProject(name: String, bandID: String, localFolderURL: URL, userID: String) async throws -> (Project, LocalProjectState) {
        try await firestore.createProject(
            name: name,
            bandID: bandID,
            localFolderURL: localFolderURL,
            userID: userID
        )
    }
    
    func updateProjectPoster(projectID: String, posterURL: String) async throws {
        try await firestore.firestore()
            .collection("projects")
            .document(projectID)
            .updateData(["posterURL": posterURL])
    }
    
    func checkDuplicateProject(name: String, bandID: String) async throws -> Bool {
        let query = firestore.firestore()
            .collection("projects")
            .whereField("bandID", isEqualTo: bandID)
            .whereField("name", isEqualTo: name)
        let snapshot = try await query.getDocuments()
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Posters
    
    func uploadProjectPoster(projectID: String, image: NSImage) async throws -> String {
        try await firestore.uploadProjectPoster(projectID: projectID, image: image)
    }
    
    // MARK: - Sync & Pull
    
    func pullProject(projectID: String, branchID: String, localRootURL: URL, state: LocalProjectState) async throws -> LocalProjectState {
        try await firestore.pullProject(
            projectID: projectID,
            branchID: branchID,
            localRootURL: localRootURL,
            state: state
        )
    }
    
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        try await firestore.fetchRemoteSnapshot(versionID: versionID)
    }
    
    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        return try await firestore.pushCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }
    func getFirestore() -> Firestore {firestore.firestore()}

    func fetchProject(projectID: String) async throws -> Project? {
        try await firestore.fetchProject(projectID: projectID)
    }
}
