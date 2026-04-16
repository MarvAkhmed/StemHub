//
//  FirestoreManager.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreManager {

    static let shared = FirestoreManager()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Raw access
    func firestore() -> Firestore { db }

    // MARK: - Projects

    func fetchAllProjects(for userID: String) async throws -> [Project] {
        let snapshot = try await db.collection("projects")
            .whereField("memberIDs", arrayContains: userID)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Project.self) }
    }

    func createProject(
        name: String,
        bandID: String,
        localFolderURL: URL,
        userID: String
    ) async throws -> (Project, ProjectSyncState) {
        let projectID = UUID().uuidString
        let branchID  = UUID().uuidString
        let project = Project(
            id: projectID,
            name: name,
            bandID: bandID,
            createdBy: userID,
            currentBranchID: branchID,
            currentVersionID: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        try db.collection("projects").document(projectID).setData(from: project)

        // Create the default "main" branch
        let branch = Branch(
            id: branchID,
            projectID: projectID,
            name: "main",
            createdAt: Date(),
            createdBy: userID)
        
        try db.collection("branches").document(branchID).setData(from: branch)
        let state = ProjectSyncState(projectID: projectID, localPath: localFolderURL.path)
        return (project, state)
    }

    func fetchProject(projectID: String) async throws -> Project? {
        let doc = try await db.collection("projects").document(projectID).getDocument()
        return try? doc.data(as: Project.self)
    }

    // MARK: - Bands
    func createBand(name: String, userID: String) async throws -> Band {
        let bandID = UUID().uuidString
        let band = Band(id: bandID, name: name, memberIDs: [userID], projectIDs: [], createdAt: Date())
        try db.collection("bands").document(bandID).setData(from: band)
        return band
    }

    func addBand(to userID: String, bandID: String) async throws {
        try await db.collection("users").document(userID)
            .updateData(["bandIDs": FieldValue.arrayUnion([bandID])])
    }
}
