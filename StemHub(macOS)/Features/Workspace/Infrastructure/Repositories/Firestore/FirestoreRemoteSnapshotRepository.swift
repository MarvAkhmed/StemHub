//
//  FirestoreRemoteSnapshotRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol

protocol ProjectNetworkStrategy {
    /// Returns the flat file list (path + hash) that represents a given version on the remote.
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
}

// MARK: - Implementation

final class DefaultProjectNetworkStrategy: ProjectNetworkStrategy {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        let versionDoc = try await db.collection("projectVersions").document(versionID).getDocument()
        guard
            versionDoc.exists,
            let version = try? versionDoc.data(as: ProjectVersion.self),
            !version.fileVersionIDs.isEmpty
        else {
            return []
        }

        let chunks = version.fileVersionIDs.chunked(into: 30)
        var snapshots: [RemoteFileSnapshot] = []

        for chunk in chunks {
            let querySnapshot = try await db.collection("fileVersions")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let batch = querySnapshot.documents.compactMap { document -> RemoteFileSnapshot? in
                guard let fileVersion = try? document.data(as: FileVersion.self) else {
                    return nil
                }

                return RemoteFileSnapshot(
                    fileID: fileVersion.fileID,
                    path: fileVersion.path,
                    hash: fileVersion.blobID,
                    versionID: versionID
                )
            }
            snapshots.append(contentsOf: batch)
        }

        return snapshots
    }
}
