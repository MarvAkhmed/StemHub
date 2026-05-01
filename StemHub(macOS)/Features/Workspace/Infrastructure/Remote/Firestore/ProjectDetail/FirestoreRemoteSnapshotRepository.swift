//
//  FirestoreRemoteSnapshotRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreRemoteSnapshotRepository: RemoteSnapshotRepository, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        guard !versionID.isEmpty else { return [] }

        let versionDoc = try await db.collection(FirestoreCollections.projectVersions.path).document(versionID).getDocument()
        guard versionDoc.exists else {
            throw SyncError.projectNotFound
        }

        let version = try versionDoc.data(as: ProjectVersion.self)
        guard !version.fileVersionIDs.isEmpty else { return [] }

        let chunks = version.fileVersionIDs.chunked(into: 30)
        var snapshots: [RemoteFileSnapshot] = []

        for chunk in chunks {
            let querySnapshot = try await db.collection(FirestoreCollections.fileVersions.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let batch = try querySnapshot.documents.map { document -> RemoteFileSnapshot in
                let fileVersion = try document.data(as: FileVersion.self)

                return RemoteFileSnapshot(
                    fileID: fileVersion.fileID,
                    path: fileVersion.path,
                    hash: fileVersion.blobID,
                    versionID: versionID,
                    versionNumber: fileVersion.versionNumber
                )
            }
            snapshots.append(contentsOf: batch)
        }

        return snapshots
    }
}
