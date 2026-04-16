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

    private let db = Firestore.firestore()

    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        // Fetch the version document to get its fileVersionIDs
        let versionDoc = try await db.collection("versions").document(versionID).getDocument()
        guard versionDoc.exists,
              let fileVersionIDs = versionDoc.data()?["fileVersionIDs"] as? [String],
              !fileVersionIDs.isEmpty
        else { return [] }

        // Batch-fetch all FileVersion documents
        let chunks = fileVersionIDs.chunked(into: 30)   // Firestore `in` limit is 30
        var snapshots: [RemoteFileSnapshot] = []

        for chunk in chunks {
            let querySnapshot = try await db.collection("fileVersions")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let batch = querySnapshot.documents.compactMap { doc -> RemoteFileSnapshot? in
                guard
                    let path = doc.data()["path"] as? String,
                    let hash = doc.data()["hash"] as? String
                else { return nil }
                return RemoteFileSnapshot(fileID: "fileid", path: path, hash: hash, versionID: versionID)
            }
            snapshots.append(contentsOf: batch)
        }

        return snapshots
    }
}

// MARK: - Helpers

private extension Array {
    /// Splits the array into sub-arrays of at most `size` elements.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
