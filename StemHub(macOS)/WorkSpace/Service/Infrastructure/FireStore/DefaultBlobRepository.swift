//
//  DefaultBlobRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation


final class DefaultBlobRepository: BlobRepository {
    private let strategy: FirestoreBlobStrategy

    init(strategy: FirestoreBlobStrategy = DefaultFirestoreBlobStrategy()) {
        self.strategy = strategy
    }

    func fetchBlob(blobID: String) async throws -> FileBlob? {
        try await strategy.fetchBlob(blobID: blobID)
    }
}
