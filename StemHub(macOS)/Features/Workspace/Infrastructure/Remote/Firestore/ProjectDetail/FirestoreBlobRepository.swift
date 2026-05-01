//
//  FirestoreBlobRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreBlobRepository: BlobRepository, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchBlob(blobID: String) async throws -> FileBlob? {
        let doc = try await db.collection(FirestoreCollections.blobs.path).document(blobID).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: FileBlob.self)
    }

    func saveBlob(_ blob: FileBlob) async throws {
        try db.collection(FirestoreCollections.blobs.path).document(blob.id).setData(from: blob)
    }
}
