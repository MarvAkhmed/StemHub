//
//  LocalFileImportService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

protocol LocalFileImporting: Sendable {
    func importFile(from sourceURL: URL,to destinationSubpath: String?, in localRootURL: URL, overwrite: Bool) throws -> URL
}

final class DefaultLocalFileImportService: LocalFileImporting, @unchecked Sendable {
    nonisolated(unsafe) private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func importFile(from sourceURL: URL, to destinationSubpath: String?, in localRootURL: URL,
                    overwrite: Bool) throws -> URL {
        
        try localRootURL.withSecurityScopedAccess {
            try sourceURL.withSecurityScopedAccess {
                let destinationURL = try resolveDestinationURL(
                    sourceURL: sourceURL,
                    destinationSubpath: destinationSubpath,
                    localRootURL: localRootURL
                )

                try fileManager.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                guard !fileManager.fileExists(atPath: destinationURL.path) else {
                    guard overwrite else {
                        throw FileImportError.destinationAlreadyExists(destinationURL)
                    }

                    try replaceExistingItem(
                        at: destinationURL,
                        withCopyOf: sourceURL
                    )
                    return destinationURL
                }

                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                return destinationURL
            }
        }
    }
}



private extension DefaultLocalFileImportService {
    func resolveDestinationURL(
        sourceURL: URL,
        destinationSubpath: String?,
        localRootURL: URL
    ) throws -> URL {
        let relativeDestination = destinationSubpath?.isEmpty == false
            ? destinationSubpath!
            : sourceURL.lastPathComponent
        let destinationURL = localRootURL
            .appendingPathComponent(relativeDestination)
            .standardizedFileURL
        let rootURL = localRootURL.standardizedFileURL
        let rootPath = rootURL.path

        guard destinationURL.path.hasPrefix(rootPath + "/") else {
            throw FileImportError.destinationOutsideWorkingDirectory(destinationURL)
        }

        return destinationURL
    }

    func replaceExistingItem(
        at destinationURL: URL,
        withCopyOf sourceURL: URL
    ) throws {
        let temporaryURL = destinationURL
            .deletingLastPathComponent()
            .appendingPathComponent(".stemhub-import-\(UUID().uuidString)")

        try fileManager.copyItem(at: sourceURL, to: temporaryURL)

        do {
            _ = try fileManager.replaceItemAt(
                destinationURL,
                withItemAt: temporaryURL,
                backupItemName: nil,
                options: []
            )
        } catch {
            try? fileManager.removeItem(at: temporaryURL)
            throw error
        }
    }

}
