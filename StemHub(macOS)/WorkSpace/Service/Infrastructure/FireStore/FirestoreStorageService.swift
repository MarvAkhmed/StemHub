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
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion]
}

// MARK: - Implementation

final class DefaultFirestoreVersionStrategy: FirestoreVersionStrategy {

    private let db = Firestore.firestore()

    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        let snapshot = try await db.collection("versions")
            .whereField("projectID", isEqualTo: projectID)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
    }

    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        let doc = try await db.collection("versions").document(versionID).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: ProjectVersion.self)
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
}

// MARK: - Helpers

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
