//
//  BlobRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol RemoteBlobRepository: Sendable {
    func fetchBlob(blobID: String) async throws -> FileBlob?
    func saveBlob(_ blob: FileBlob) async throws
}

protocol BlobRepository: RemoteBlobRepository {}
