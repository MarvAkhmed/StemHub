//
//  FileUploadService.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseStorage

protocol FileUploadStrategy {
    func uploadFile(localURL: URL, blobID: String) async throws -> String
    func downloadFile(storagePath: String, to localURL: URL) async throws
}


struct FileUploadService: FileUploadStrategy {
    func uploadFile(localURL: URL, blobID: String) async throws -> String {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("blobs/\(blobID)")
        _ = try await storageRef.putFileAsync(from: localURL)
        return storageRef.fullPath
    }
    
    func downloadFile(storagePath: String, to localURL: URL) async throws {
        let storage = Storage.storage()
        let storageRef = storage.reference(withPath: storagePath)
        _ = try await storageRef.writeAsync(toFile: localURL)
    }
}
