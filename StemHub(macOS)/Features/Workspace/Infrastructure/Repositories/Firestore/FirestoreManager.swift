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
        let userSnapshot = try await db.collection("users").document(userID).getDocument()
        let bandIDs = userSnapshot.data()?["bandIDs"] as? [String] ?? []
        guard !bandIDs.isEmpty else { return [] }

        var projects: [Project] = []
        for chunk in bandIDs.chunked(into: 30) {
            let snapshot = try await db.collection("projects")
                .whereField("bandID", in: chunk)
                .getDocuments()
            projects.append(contentsOf: snapshot.documents.compactMap { try? $0.data(as: Project.self) })
        }

        return projects.sorted { $0.updatedAt > $1.updatedAt }
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
        let branch = Branch(
            id: branchID,
            projectID: projectID,
            name: "main",
            headVersionID: nil,
            createdAt: Date(),
            createdBy: userID
        )

        let batch = db.batch()
        try batch.setData(from: project, forDocument: db.collection("projects").document(projectID))
        try batch.setData(from: branch, forDocument: db.collection("branches").document(branchID))
        batch.updateData(
            ["projectIDs": FieldValue.arrayUnion([projectID])],
            forDocument: db.collection("bands").document(bandID)
        )
        try await batch.commit()

        let state = ProjectSyncState(projectID: projectID, localPath: localFolderURL.path)
        return (project, state)
    }

    func fetchProject(projectID: String) async throws -> Project? {
        let doc = try await db.collection("projects").document(projectID).getDocument()
        return try? doc.data(as: Project.self)
    }

    func deleteProject(projectID: String, bandID: String) async throws {
        let versionSnapshot = try await db.collection("projectVersions")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()
        let branchSnapshot = try await db.collection("branches")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()
        let commentSnapshot = try await db.collection("comments")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()
        let commitSnapshot = try await db.collection("commits")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()

        let fileVersionIDs = versionSnapshot.documents
            .flatMap { $0.data()["fileVersionIDs"] as? [String] ?? [] }
        let fileVersionReferences = Set(fileVersionIDs).map { id in
            db.collection("fileVersions").document(id)
        }

        var referencesToDelete = [db.collection("projects").document(projectID)]
        referencesToDelete.append(contentsOf: versionSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: branchSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: commentSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: commitSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: fileVersionReferences)

        for chunk in referencesToDelete.chunked(into: 400) {
            let batch = db.batch()
            for reference in chunk {
                batch.deleteDocument(reference)
            }
            try await batch.commit()
        }

        try await db.collection("bands").document(bandID)
            .updateData([
                "projectIDs": FieldValue.arrayRemove([projectID])
            ])
    }

    // MARK: - Bands
    func createBand(
        name: String,
        primaryAdminUserID: String,
        adminUserIDs: [String],
        memberUserIDs: [String]
    ) async throws -> Band {
        let bandID = UUID().uuidString
        let resolvedAdminUserIDs = NSOrderedSet(array: [primaryAdminUserID] + adminUserIDs)
            .array
            .compactMap { $0 as? String }
        let resolvedMemberUserIDs = NSOrderedSet(array: [primaryAdminUserID] + memberUserIDs + resolvedAdminUserIDs)
            .array
            .compactMap { $0 as? String }
        let band = Band(
            id: bandID,
            name: name,
            adminUserID: primaryAdminUserID,
            adminUserIDs: resolvedAdminUserIDs,
            memberIDs: resolvedMemberUserIDs,
            projectIDs: [],
            createdAt: Date()
        )
        try db.collection("bands").document(bandID).setData(from: band)
        return band
    }

    func fetchBand(bandID: String) async throws -> Band? {
        let document = try await db.collection("bands").document(bandID).getDocument()
        guard document.exists else { return nil }
        return try document.data(as: Band.self)
    }

    func addBand(to userID: String, bandID: String) async throws {
        try await db.collection("users").document(userID)
            .updateData(["bandIDs": FieldValue.arrayUnion([bandID])])
    }

    func addMember(userID: String, to bandID: String) async throws {
        try await db.collection("bands").document(bandID)
            .updateData(["memberIDs": FieldValue.arrayUnion([userID])])
    }

    func linkProject(_ projectID: String, to bandID: String) async throws {
        try await db.collection("bands").document(bandID)
            .updateData(["projectIDs": FieldValue.arrayUnion([projectID])])
    }
}
