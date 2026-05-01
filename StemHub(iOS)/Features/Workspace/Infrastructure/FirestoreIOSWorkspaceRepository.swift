//
//  FirestoreIOSWorkspaceRepository.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import FirebaseFirestore

protocol IOSWorkspaceLoading {
    func fetchWorkspace(for userID: String) async throws -> IOSWorkspaceSnapshot
}

final class FirestoreIOSWorkspaceRepository: IOSWorkspaceLoading {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchWorkspace(for userID: String) async throws -> IOSWorkspaceSnapshot {
        let userDocument = try await db.collection(FirestoreCollections.users.path).document(userID).getDocument()
        let bandIDs = userDocument.data()?["bandIDs"] as? [String] ?? []

        guard !bandIDs.isEmpty else {
            return IOSWorkspaceSnapshot(bands: [], projects: [])
        }

        async let bands = fetchBands(for: bandIDs)
        async let projects = fetchProjects(for: bandIDs)

        return try await IOSWorkspaceSnapshot(
            bands: bands,
            projects: projects
        )
    }

    private func fetchBands(for bandIDs: [String]) async throws -> [IOSBandSummary] {
        var bands: [IOSBandSummary] = []

        for chunk in bandIDs.chunked(into: 30) {
            let snapshot = try await db.collection(FirestoreCollections.bands.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            bands.append(contentsOf: snapshot.documents.compactMap { $0.decoded(as: IOSBandSummary.self) })
        }

        return bands.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func fetchProjects(for bandIDs: [String]) async throws -> [IOSProjectSummary] {
        var projects: [IOSProjectSummary] = []

        for chunk in bandIDs.chunked(into: 30) {
            let snapshot = try await db.collection(FirestoreCollections.projects.path)
                .whereField("bandID", in: chunk)
                .getDocuments()

            projects.append(contentsOf: snapshot.documents.compactMap { $0.decoded(as: IOSProjectSummary.self) })
        }

        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }
}
