//
//  FileUploadService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseStorage

// MARK: - Protocol

protocol FileUploadStrategy {
    /// Upload a local file to Firebase Storage and return the storage path used.
    func uploadFile(localURL: URL, storagePath: String) async throws -> String

    /// Download a file from Firebase Storage to a local destination URL.
    func downloadFile(storagePath: String, to localURL: URL) async throws
}

// MARK: - Implementation

final class FileUploadService: FileUploadStrategy {

    private let storage = Storage.storage()

    func uploadFile(localURL: URL, storagePath: String) async throws -> String {
        let ref = storage.reference().child(storagePath)
        _ = try await ref.putFileAsync(from: localURL)
        return storagePath
    }

    func downloadFile(storagePath: String, to localURL: URL) async throws {
        let ref = storage.reference().child(storagePath)
        _ = try await ref.writeAsync(toFile: localURL)
    }
}
