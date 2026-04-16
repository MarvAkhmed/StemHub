//
//  FirestoreBlobRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol

protocol FirestoreBlobStrategy {
    func fetchBlob(blobID: String) async throws -> FileBlob?
    func saveBlob(_ blob: FileBlob) async throws
}

// MARK: - Implementation

final class DefaultFirestoreBlobStrategy: FirestoreBlobStrategy {

    private let db = Firestore.firestore()

    func fetchBlob(blobID: String) async throws -> FileBlob? {
        let doc = try await db.collection("blobs").document(blobID).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: FileBlob.self)
    }

    func saveBlob(_ blob: FileBlob) async throws {
        try db.collection("blobs").document(blob.id).setData(from: blob)
    }
}
