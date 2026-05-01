//
//  LocalFileSnapshotProvider.swift
//  StemHub(macOS)
//
// Created by Marwa Awad on 27.04.2026.
//

import Foundation

protocol LocalFileSnapshotProviding: Sendable {
    nonisolated func scan(folderURL: URL) async throws -> [LocalFile]
}

struct LocalFileSnapshotProvider: LocalFileSnapshotProviding {
    nonisolated private let scanner: FileScannerStrategy
    nonisolated private let fileHasher: FileHashing

    init(
        scanner: FileScannerStrategy,
        fileHasher: FileHashing
    ) {
        self.scanner = scanner
        self.fileHasher = fileHasher
    }

    nonisolated func scan(folderURL: URL) async throws -> [LocalFile] {
        let fileURLs = uniqueStandardizedFileURLs(
            from: try scanner.fileURLs(in: folderURL)
        )

        return try await fileURLs.asyncCompactMap { url in
            guard let relativePath = scanner.relativePath(for: url, in: folderURL) else {
                return nil
            }

            let values = try url.resourceValues(forKeys: [.fileSizeKey])

            return LocalFile(path: relativePath,
                             name: url.lastPathComponent,
                             fileExtension: url.pathExtension,
                             size: Int64(values.fileSize ?? 0),
                             hash: try await fileHasher.fileHash(for: url),
                             isDirectory: false)
        }
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

private extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?)async throws -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)

        for element in self {
            try Task.checkCancellation()
            if let value = try await transform(element) {
                result.append(value)
            }
        }

        return result
    }
}
