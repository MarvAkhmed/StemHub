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
        var files: [LocalFile] = []
        try await withThrowingTaskGroup(of: LocalFile?.self) { group in
            for try await url in scanner.fileURLStream(in: folderURL) {
                group.addTask {
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
            
            for try await file in group {
                if let file {
                    files.append(file)
                }
            }
        }
        return files.sorted { $0.path < $1.path }
    }
}
