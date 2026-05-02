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
        let fileURLs = try await scanner.fileURLs(in: folderURL)
            .uniqueStandardizedFileURLs()
        
        return try await fileURLs.asyncCompactMap { url in
            guard let relativePath = scanner.relativePath(for: url, in: folderURL) else { return nil }
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let hash = try await fileHasher.fileHash(for: url)
            
            return LocalFile(path: relativePath,
                             name: url.lastPathComponent,
                             fileExtension: url.pathExtension,
                             size: Int64(values.fileSize ?? 0),
                             hash: hash,
                             isDirectory: false)
        }
    }
}
