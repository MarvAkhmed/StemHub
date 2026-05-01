//
//  LocalProjectWorkingDirectoryInitializer.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

protocol LocalProjectWorkingDirectoryInitializing: Sendable {
    /// Initialises a local working directory for a project.
    /// - Parameters:
    ///   - project: The project to clone locally.
    ///   - parentURL: The user-chosen parent folder from NSOpenPanel.
    ///   - checkoutFiles: The files at the current HEAD version to download.
    /// - Returns: The URL of the created working directory.
    func initializeWorkingDirectory(for project: Project, in parentURL: URL, checkoutFiles: [WorkingTreeCheckoutFile] ) async throws -> URL
}

final class DefaultLocalProjectWorkingDirectoryInitializer: LocalProjectWorkingDirectoryInitializing, @unchecked Sendable {
    nonisolated private let fileTransferStrategy: RemoteFileTransferStrategy
    nonisolated private let stateStore: ProjectStateStore
    nonisolated private let bookmarkStrategy: BookmarkStrategy
    // FileManager is used as a stateless filesystem facade here and is not shared mutably.
    nonisolated(unsafe) private let fileManager: FileManager

    init(
        fileTransferStrategy: RemoteFileTransferStrategy,
        stateStore: ProjectStateStore,
        bookmarkStrategy: BookmarkStrategy,
        fileManager: FileManager = .default
    ) {
        self.fileTransferStrategy = fileTransferStrategy
        self.stateStore = stateStore
        self.bookmarkStrategy = bookmarkStrategy
        self.fileManager = fileManager
    }

    func initializeWorkingDirectory(for project: Project, in parentURL: URL,
                                    checkoutFiles: [WorkingTreeCheckoutFile] ) async throws -> URL {
        let folderName = sanitizedFolderName(for: project.name)
        let projectFolderURL = parentURL.appendingPathComponent(folderName, isDirectory: true)

        return try await parentURL.withSecurityScopedAccess {
            guard !fileManager.fileExists(atPath: projectFolderURL.path) else {
                throw LocalProjectWorkingDirectoryInitializationError.destinationAlreadyExists(projectFolderURL)
            }

            try fileManager.createDirectory(
                at: projectFolderURL,
                withIntermediateDirectories: true
            )

            do {
                try await download(checkoutFiles, to: projectFolderURL)
            } catch {
                try cleanupPartiallyInitializedDirectory(
                    at: projectFolderURL,
                    initializationError: error
                )
            }

            let bookmarkData = try bookmarkStrategy.createBookmark(for: projectFolderURL)
            stateStore.setLocalPath(projectFolderURL.path, for: project.id)
            stateStore.saveBookmarkData(bookmarkData, for: project.id)

            return projectFolderURL
        }
    }
}

private extension DefaultLocalProjectWorkingDirectoryInitializer {
    func sanitizedFolderName(for projectName: String) -> String {
        let illegalCharacters = CharacterSet(charactersIn: ":/\u{0}")
        let sanitized = projectName.unicodeScalars
            .map { illegalCharacters.contains($0) ? "-" : String($0) }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitized.isEmpty ? "Project" : sanitized
    }

    func download(
        _ files: [WorkingTreeCheckoutFile],
        to projectFolderURL: URL
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for file in files {
                group.addTask { [fileManager, fileTransferStrategy] in
                    let destinationURL = projectFolderURL.appendingPathComponent(file.path)
                    try fileManager.createDirectory(
                        at: destinationURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                    try await fileTransferStrategy.downloadFile(
                        storagePath: file.storagePath,
                        to: destinationURL
                    )
                }
            }

            try await group.waitForAll()
        }
    }

    func cleanupPartiallyInitializedDirectory(
        at projectFolderURL: URL,
        initializationError: Error
    ) throws -> Never {
        do {
            try fileManager.removeItem(at: projectFolderURL)
        } catch let cleanupError {
            throw LocalProjectWorkingDirectoryInitializationError.cleanupFailed(
                initializationError: initializationError,
                cleanupError: cleanupError
            )
        }

        throw initializationError
    }
}
