//
//  ProjectFolderService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

typealias ProjectFileService = ProjectFolderService
typealias DefaultProjectFileService = DefaultProjectFolderService

protocol ProjectFolderService {
    func resolveFolderURL(for projectID: String) -> URL?
    func fileTree(for projectID: String) -> [FileTreeNode]
    func musicFiles(for project: Project) throws -> [MusicFile]
    func updateFolderReference(projectID: String, folderURL: URL) throws
}

final class DefaultProjectFolderService: ProjectFolderService {
    private let fileManager = FileManager.default
    private let stateStore: ProjectStateStore
    private let bookmarkStrategy: BookmarkStrategy
    private let scanner: FileScanner

    init(
        stateStore: ProjectStateStore = UserDefaultsProjectStateStore(),
        bookmarkStrategy: BookmarkStrategy = DefaultBookmarkStrategy(),
        scanner: FileScanner = LocalFileScanner()
    ) {
        self.stateStore = stateStore
        self.bookmarkStrategy = bookmarkStrategy
        self.scanner = scanner
    }

    func resolveFolderURL(for projectID: String) -> URL? {
        let state = stateStore.syncState(for: projectID)

        if let bookmarkData = stateStore.bookmarkData(for: projectID),
           let url = try? bookmarkStrategy.resolveBookmark(bookmarkData) {
            return url
        }

        guard !state.localPath.isEmpty else { return nil }

        let fallbackURL = URL(fileURLWithPath: state.localPath)
        return fileManager.isReadableFile(atPath: fallbackURL.path) ? fallbackURL : nil
    }

    func fileTree(for projectID: String) -> [FileTreeNode] {
        guard let folderURL = resolveFolderURL(for: projectID) else { return [] }

        let didStartAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        return buildFileTree(at: folderURL)
    }

    func musicFiles(for project: Project) throws -> [MusicFile] {
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

    func updateFolderReference(projectID: String, folderURL: URL) throws {
        let bookmark = try bookmarkStrategy.createBookmark(for: folderURL)
        stateStore.saveBookmarkData(bookmark, for: projectID)

        var state = stateStore.syncState(for: projectID)
        state.localPath = folderURL.path
        stateStore.saveSyncState(state)
    }

    private func buildFileTree(at url: URL) -> [FileTreeNode] {
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

