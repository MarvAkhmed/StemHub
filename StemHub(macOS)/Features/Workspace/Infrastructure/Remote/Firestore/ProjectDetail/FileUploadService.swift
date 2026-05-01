//
//  FileUploadService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseStorage

final class FileUploadService: RemoteFileTransferStrategy, RemoteBlobStorage, RemoteBlobByteCleaning, @unchecked Sendable {
    
    nonisolated private let storage = Storage.storage()
    
    func uploadFile(localURL: URL, storagePath: String) async throws -> String {
        let ref = storage.reference().child(storagePath)
        _ = try await ref.putFileAsync(from: localURL)
        return storagePath
    }
    
    func downloadFile(storagePath: String, to localURL: URL) async throws {
        let ref = storage.reference().child(storagePath)
        _ = try await ref.writeAsync(toFile: localURL)
    }

    func upload(data: Data, to path: String) async throws -> URL {
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(data)
        return try await ref.downloadURL()
    }

    func download(from path: String) async throws -> Data {
        let ref = storage.reference().child(path)
        return try await ref.data(maxSize: Int64.max)
    }

    func delete(path: String) async throws {
        let ref = storage.reference().child(path)
        try await delete(ref)
    }
    
    func deleteBlobBytes(storagePaths: [String]) async throws {
        let uniquePaths = Set(storagePaths).filter { !$0.isEmpty }
        guard !uniquePaths.isEmpty else { return }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for storagePath in uniquePaths {
                group.addTask { [self] in
                    let ref = self.storage.reference().child(storagePath)
                    try await self.delete(ref)
                }
            }
            try await group.waitForAll()
        }
    }
}

private extension FileUploadService {
    func delete(_ ref: StorageReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

// VERIFICATION
// - [ ] Deleting N blobs issues all N Storage delete requests concurrently, not serially.
// - [ ] If any single deletion throws, the error propagates out of deleteBlobBytes
//       and is received by the caller.
// - [ ] Passing an empty array is a no-op — no requests made, no error thrown.
// - [ ] Passing an array containing only empty strings is a no-op.
// - [ ] The private delete(_ ref: StorageReference) helper is identical to the original.
