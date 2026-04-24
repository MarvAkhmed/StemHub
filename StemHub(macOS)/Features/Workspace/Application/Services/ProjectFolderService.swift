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
    nonisolated(unsafe) private let fileManager = FileManager.default
    nonisolated(unsafe) private let stateStore: ProjectStateStore
    nonisolated(unsafe) private let bookmarkStrategy: BookmarkStrategy
    nonisolated(unsafe) private let scanner: FileScanner

    init(
        stateStore: ProjectStateStore,
        bookmarkStrategy: BookmarkStrategy,
        scanner: FileScanner
    ) {
        self.stateStore = stateStore
        self.bookmarkStrategy = bookmarkStrategy
        self.scanner = scanner
    }

    nonisolated func resolveFolderURL(for projectID: String) -> URL? {
        let state = stateStore.syncState(for: projectID)

        if let bookmarkData = stateStore.bookmarkData(for: projectID),
           let url = try? bookmarkStrategy.resolveBookmark(bookmarkData) {
            return url
        }

        guard !state.localPath.isEmpty else { return nil }

        let fallbackURL = URL(fileURLWithPath: state.localPath)
        return fileManager.isReadableFile(atPath: fallbackURL.path) ? fallbackURL : nil
    }

    nonisolated func fileTree(for projectID: String) -> [FileTreeNode] {
        guard let folderURL = resolveFolderURL(for: projectID) else { return [] }

        let didStartAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        return buildFileTree(at: folderURL)
    }

    nonisolated func musicFiles(for project: Project) throws -> [MusicFile] {
        guard let folderURL = resolveFolderURL(for: project.id) else { return [] }

        return try scanner.scan(folderURL: folderURL)
            .filter { !$0.isDirectory }
            .map {
                MusicFile(
                    id: $0.id,
                    projectID: project.id,
                    name: $0.name,
                    fileExtension: $0.fileExtension,
                    path: $0.path,
                    capabilities: .playable,
                    currentVersionID: project.currentVersionID,
                    availableFormats: [],
                    createdAt: Date()
                )
            }
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

        let rootPath = rootURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path

        guard filePath.hasPrefix(rootPath) else { return nil }

        return filePath
            .replacingOccurrences(of: rootPath, with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    nonisolated private func buildFileTree(at url: URL) -> [FileTreeNode] {
        func buildNode(at nodeURL: URL) -> FileTreeNode? {
            let isDirectory = (try? nodeURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            var node = FileTreeNode(url: nodeURL, isDirectory: isDirectory)

            if isDirectory {
                let contents = (try? fileManager.contentsOfDirectory(at: nodeURL, includingPropertiesForKeys: nil)) ?? []
                node.children = contents.compactMap(buildNode)
            }

            return node
        }

        return buildNode(at: url)?.children ?? []
    }
}
