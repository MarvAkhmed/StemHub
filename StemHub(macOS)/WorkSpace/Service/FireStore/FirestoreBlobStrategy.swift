//
//  FirestoreBlobStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore

protocol FirestoreBlobStrategy {
    func fetchBlob(blobID: String) async throws -> FileBlob?
}

struct DefaultFirestoreBlobStrategy: FirestoreBlobStrategy {
    private let db = Firestore.firestore()
    
    func fetchBlob(blobID: String) async throws -> FileBlob? {
        let doc = try await db.collection("blobs").document(blobID).getDocument()
        return try? doc.data(as: FileBlob.self)
    }
}
