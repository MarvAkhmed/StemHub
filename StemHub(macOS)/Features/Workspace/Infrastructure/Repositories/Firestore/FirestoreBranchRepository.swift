//
//  FirestoreBranchRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol
protocol FirestoreBranchStrategy {
    func fetchBranches(projectID: String) async throws -> [Branch]
    func fetchBranch(branchID: String) async throws -> Branch?
    func updateHeadVersionID(_ versionID: String, branchID: String) async throws
    func createBranch(
        projectID: String,
        name: String,
        headVersionID: String?,
        createdBy: String
    ) async throws -> Branch
}

// MARK: - Implementation
final class DefaultFirestoreBranchStrategy: FirestoreBranchStrategy {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchBranches(projectID: String) async throws -> [Branch] {
        let snapshot = try await db.collection("branches")
            .whereField("projectID", isEqualTo: projectID)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Branch.self) }
    }

    func fetchBranch(branchID: String) async throws -> Branch? {
        let doc = try await db.collection("branches").document(branchID).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: Branch.self)
    }

    func updateHeadVersionID(_ versionID: String, branchID: String) async throws {
        try await db.collection("branches")
            .document(branchID)
            .updateData(["headVersionID": versionID])
    }

    func createBranch(
        projectID: String,
        name: String,
        headVersionID: String?,
        createdBy: String
    ) async throws -> Branch {
        let branch = Branch(
            id: UUID().uuidString,
            projectID: projectID,
            name: name,
            headVersionID: headVersionID,
            createdAt: Date(),
            createdBy: createdBy
        )

        try db.collection("branches").document(branch.id).setData(from: branch)
        return branch
    }
}
