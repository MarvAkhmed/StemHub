//
//  FirestoreStorageService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - FirestoreVersionStrategy
//
// This protocol is used by DefaultVersionRepository (Infrastructure/FireStore).
// Keeping it here next to the Firestore layer avoids a circular dependency
// between the repository and the strategy files.

protocol FirestoreVersionStrategy {
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion]
    func fetchVersion(versionID: String) async throws -> ProjectVersion?
    func fetchVersions(versionIDs: [String]) async throws -> [ProjectVersion]
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion]
    func approveVersion(versionID: String, approvedBy userID: String) async throws
}

// MARK: - Implementation

final class DefaultFirestoreVersionStrategy: FirestoreVersionStrategy {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        let snapshot = try await db.collection("projectVersions")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: ProjectVersion.self) }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id > rhs.id
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        let doc = try await db.collection("projectVersions").document(versionID).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: ProjectVersion.self)
    }

    func fetchVersions(versionIDs: [String]) async throws -> [ProjectVersion] {
        guard !versionIDs.isEmpty else { return [] }

        let chunks = Array(Set(versionIDs)).chunked(into: 30)
        var results: [ProjectVersion] = []

        for chunk in chunks {
            let snapshot = try await db.collection("projectVersions")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let batch = snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
            results.append(contentsOf: batch)
        }

        return results
    }

    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion] {
        guard !fileVersionIDs.isEmpty else { return [] }

        let chunks = fileVersionIDs.chunked(into: 30)
        var results: [FileVersion] = []

        for chunk in chunks {
            let querySnapshot = try await db.collection("fileVersions")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let batch = querySnapshot.documents.compactMap { try? $0.data(as: FileVersion.self) }
            results.append(contentsOf: batch)
        }
        return results
    }

    func approveVersion(versionID: String, approvedBy userID: String) async throws {
        try await db.collection("projectVersions")
            .document(versionID)
            .updateData([
                "approvalState": ProjectVersionApprovalState.approved.rawValue,
                "approvedByUserID": userID,
                "approvedAt": Date()
            ])
    }
}
