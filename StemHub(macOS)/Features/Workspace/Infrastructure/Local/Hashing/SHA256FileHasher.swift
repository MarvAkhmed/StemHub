//
//  SHA256FileHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import CryptoKit
import Foundation

protocol FileHashing: Sendable {
    nonisolated func fileHash(for url: URL) async throws -> String
}

struct SHA256FileHasher: FileHashing {
    private let chunkSize = 1024 * 1024

    nonisolated func fileHash(for url: URL) async throws -> String {
        let chunkSize = chunkSize

        return try await Task.detached(priority: .utility) {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }

            var hasher = SHA256()

            while let data = try handle.read(upToCount: chunkSize), !data.isEmpty {
                try Task.checkCancellation()
                hasher.update(data: data)
            }

            return hasher.finalize().hexString
        }.value
    }
}

private extension SHA256.Digest {
    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
