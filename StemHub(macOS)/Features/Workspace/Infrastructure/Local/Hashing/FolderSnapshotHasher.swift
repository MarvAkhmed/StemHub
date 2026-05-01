//
//  FolderSnapshotHasher.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import CryptoKit
import Foundation

protocol FolderSnapshotHashing: Sendable {
    nonisolated func folderSnapshotHash(for folderURL: URL) async throws -> String
}

struct FolderSnapshotHasher: FolderSnapshotHashing {
    private let scanner: FileScannerStrategy
    private let fileHasher: FileHashing

    init(
        scanner: FileScannerStrategy,
        fileHasher: FileHashing
    ) {
        self.scanner = scanner
        self.fileHasher = fileHasher
    }

    nonisolated func folderSnapshotHash(for folderURL: URL) async throws -> String {
        let fileURLs = uniqueStandardizedFileURLs(
            from: try scanner.fileURLs(in: folderURL)
        )
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

        var canonicalEntries: [String] = []
        canonicalEntries.reserveCapacity(fileURLs.count)

        for fileURL in fileURLs {
            try Task.checkCancellation()

            guard let relativePath = scanner.relativePath(for: fileURL, in: folderURL) else {
                continue
            }

            let values = try fileURL.resourceValues(forKeys: [
                .contentModificationDateKey,
                .fileSizeKey
            ])

            let modifiedAt = values.contentModificationDate?
                .timeIntervalSince1970
                .rounded(.towardZero) ?? 0

            let fileHash = try await fileHasher.fileHash(for: fileURL)

            canonicalEntries.append(
                "\(relativePath)|\(values.fileSize ?? 0)|\(Int64(modifiedAt))|\(fileHash)"
            )
        }

        let canonicalSnapshot = canonicalEntries.joined(separator: "\n")
        let digest = SHA256.hash(data: Data(canonicalSnapshot.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    nonisolated private func uniqueStandardizedFileURLs(from urls: [URL]) -> [URL] {
        var seenPaths = Set<String>()
        var uniqueURLs: [URL] = []
        uniqueURLs.reserveCapacity(urls.count)

        for url in urls {
            let standardizedURL = url.standardizedFileURL
            if seenPaths.insert(standardizedURL.path).inserted {
                uniqueURLs.append(standardizedURL)
            }
        }

        return uniqueURLs
    }
}
