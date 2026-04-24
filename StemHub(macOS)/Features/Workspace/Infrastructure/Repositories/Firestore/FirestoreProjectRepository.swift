//
//  FirestoreProjectRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreProjectRepository: ProjectRepository {
    private let firestore: FirestoreManager

    init(firestore: FirestoreManager = .shared) {
        self.firestore = firestore
    }

    func fetchProjects(for userID: String) async throws -> [Project] {
        try await firestore.fetchAllProjects(for: userID)
    }

    func createProject(name: String, bandID: String, localFolderURL: URL, userID: String) async throws -> (Project, ProjectSyncState) {
        try await firestore.createProject(name: name, bandID: bandID, localFolderURL: localFolderURL, userID: userID)
    }

    func fetchProject(projectID: String) async throws -> Project? {
        try await firestore.fetchProject(projectID: projectID)
    }

    func deleteProject(projectID: String, bandID: String) async throws {
        try await firestore.deleteProject(projectID: projectID, bandID: bandID)
    }

    func isDuplicateProject(name: String, bandID: String) async throws -> Bool {
        let snapshot = try await firestore.firestore()
            .collection("projects")
            .whereField("bandID", isEqualTo: bandID)
            .whereField("name", isEqualTo: name)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    func updatePosterBase64(projectID: String, base64: String) async throws {
        try await firestore.firestore()
            .collection("projects")
            .document(projectID)
            .updateData([
                "posterBase64": base64,
                "updatedAt": Date()
            ])
    }

    func updateWorkspaceState(
        projectID: String,
        currentBranchID: String,
        currentVersionID: String?
    ) async throws {
        try await firestore.firestore()
            .collection("projects")
            .document(projectID)
            .updateData([
                "currentBranchID": currentBranchID,
                "currentVersionID": currentVersionID ?? "",
                "updatedAt": Date()
            ])
    }
}
