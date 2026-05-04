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
        let fileURLs = try await uniqueSortedFileURLs(in: folderURL)
        let canonicalEntries = try await canonicalEntries(for: fileURLs, folderURL: folderURL) // H_file
        //  Equal hash → unconditional DSP skip. Different hash → audio candidate.
        return hashCanonicalSnapshot(from: canonicalEntries) // has the full folder // H_folder  // *Time:** `O(B)
    }
}

private extension FolderSnapshotHasher {
    // - **Time:** `O(N log N)`.
    // **Space:** `O(N)`.
    nonisolated func uniqueSortedFileURLs(in folderURL: URL) async throws -> [URL] {
        var urls: [URL] = []

        for try await fileURL in scanner.fileURLStream(in: folderURL) {
            urls.append(fileURL)
        }

        return urls
            .uniqueStandardizedFileURLs()
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    nonisolated func canonicalEntries(for fileURLs: [URL], folderURL: URL) async throws -> [String] {
        var entries: [String] = []
        entries.reserveCapacity(fileURLs.count)

        for fileURL in fileURLs {
            try Task.checkCancellation()

            guard let relativePath = scanner.relativePath(for: fileURL, in: folderURL) else {
                continue
            }

            let entry = try await canonicalEntry(
                fileURL: fileURL,
                relativePath: relativePath
            )

            entries.append(entry)
        }

        return entries
    }

    nonisolated func canonicalEntry(fileURL: URL, relativePath: String) async throws -> String {
        let values = try fileURL.resourceValues(forKeys: [
            .contentModificationDateKey,
            .fileSizeKey
        ])

        let modifiedAt = values.contentModificationDate?
            .timeIntervalSince1970
            .rounded(.towardZero) ?? 0

        let fileHash = try await fileHasher.fileHash(for: fileURL)

        return "\(relativePath)|\(values.fileSize ?? 0)|\(Int64(modifiedAt))|\(fileHash)"
    }

    nonisolated func hashCanonicalSnapshot(from entries: [String]) -> String {
        let canonicalSnapshot = entries.joined(separator: "\n")
        return SHA256.hash(data: Data(canonicalSnapshot.utf8)).hexString
    }
}
