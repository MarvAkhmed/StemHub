//
//  ProjectFolderService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectFolderResolving: Sendable {
    nonisolated func resolveFolderURL(for projectID: String) -> URL?
}

protocol ProjectFileTreeProviding: Sendable {
    nonisolated func fileTree(for projectID: String) -> [FileTreeNode]
}

protocol ProjectFolderReferenceUpdating: Sendable {
    nonisolated func updateFolderReference(projectID: String, folderURL: URL) throws
}

protocol ProjectPathRelating: Sendable {
    nonisolated func relativePath(for fileURL: URL, projectID: String) -> String?
}

protocol ProjectFolderService:
    ProjectFolderResolving,
    ProjectFileTreeProviding,
    ProjectFolderReferenceUpdating,
    ProjectPathRelating {}

typealias ProjectLocalWorkspaceFolderAccessing =
    ProjectFolderResolving &
    ProjectFileTreeProviding &
    ProjectFolderReferenceUpdating &
    ProjectPathRelating

typealias ProjectMIDIFolderAccessing =
    ProjectFolderResolving &
    ProjectFileTreeProviding &
    ProjectPathRelating

final class DefaultProjectFolderService: ProjectFolderService, @unchecked Sendable {
    nonisolated private let stateStore: ProjectStateStore
    nonisolated private let bookmarkStrategy: BookmarkStrategy
    private let scanner: FileScannerStrategy

    init(
        stateStore: ProjectStateStore,
        bookmarkStrategy: BookmarkStrategy,
        scanner: FileScannerStrategy
    ) {
        self.stateStore = stateStore
        self.bookmarkStrategy = bookmarkStrategy
        self.scanner = scanner
    }
    
    nonisolated func resolveFolderURL(for projectID: String) -> URL? {
        let state = stateStore.syncState(for: projectID)

        if let bookmarkData = stateStore.bookmarkData(for: projectID),
            let url = resolveBookmarkedURL(bookmarkData, projectID: projectID) {
            return url
        }

        guard !state.localPath.isEmpty else { return nil }

        let fallbackURL = URL(fileURLWithPath: state.localPath)
        return FileManager.default.isReadableFile(atPath: fallbackURL.path) ? fallbackURL : nil
    }

    nonisolated func fileTree(for projectID: String) -> [FileTreeNode] {
        guard let folderURL = resolveFolderURL(for: projectID) else { return [] }
        return (try? scanner.fileTree(folderURL: folderURL)) ?? []
    }

    nonisolated func musicFiles(for project: Project) async throws -> [MusicFile] {
        guard let folderURL = resolveFolderURL(for: project.id) else {
            return []
        }

        var musicFiles: [MusicFile] = []

        for try await fileURL in scanner.fileURLStream(in: folderURL) {
            guard let path = scanner.relativePath(for: fileURL, in: folderURL) else {
                continue
            }

            let fileExtension = fileURL.pathExtension

            let musicFile = MusicFile(
                id: path,
                projectID: project.id,
                name: fileURL.lastPathComponent,
                fileExtension: fileExtension,
                path: path,
                capabilities: .playable,
                currentVersionID: project.currentVersionID,
                availableFormats: [],
                createdAt: Date()
            )

            musicFiles.append(musicFile)
        }

        return musicFiles.sorted { $0.path < $1.path }
    }

    nonisolated func updateFolderReference(projectID: String, folderURL: URL) throws {
        let bookmark = try bookmarkStrategy.createBookmark(for: folderURL)
        stateStore.saveBookmarkData(bookmark, for: projectID)

        var state = stateStore.syncState(for: projectID)
        state.localPath = folderURL.path
        stateStore.saveSyncState(state)
    }

    nonisolated func relativePath(for fileURL: URL, projectID: String) -> String? {
        guard let rootURL = resolveFolderURL(for: projectID) else { return nil }
        return scanner.relativePath(for: fileURL, in: rootURL)
    }
}

//MARK: - Helpers
private extension DefaultProjectFolderService {
    nonisolated func resolveBookmarkedURL(_ data: Data, projectID: String) -> URL? {
        guard let resolved = try? bookmarkStrategy.resolveBookmark(data) else {
            return nil
        }
        
        if resolved.isStale {
            try? updateFolderReference(projectID: projectID, folderURL: resolved.url)
        }
        
        return resolved.url
    }
}
