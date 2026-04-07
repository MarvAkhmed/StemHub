//
//  ProjectFileService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

protocol ProjectFileService{
    func fileTree(for projectID: String, localPath: String) -> [FileTreeNode]
    func accessibleFolderURL(for projectID: String, bookmarkData: Data?, localPath: String) -> URL?
    func saveBookmark(_ data: Data, for projectID: String)
    func localPath(for projectID: String) -> String
}

final class DefaultProjectFileService: ProjectFileService {
    private let fileManager = FileManager.default
    private let persistence: ProjectPersistenceStrategy
    
    init(persistence: ProjectPersistenceStrategy = DefaultProjectPersistenceStrategy()) {
        self.persistence = persistence
    }
    
    func localPath(for projectID: String) -> String {
        persistence.getLocalPath(for: projectID)
    }
    
    func saveBookmark(_ data: Data, for projectID: String) {
        persistence.storeBookmark(data: data, for: projectID)
    }
    
    func accessibleFolderURL(for projectID: String, bookmarkData: Data?, localPath: String) -> URL? {
        if let bookmarkData = bookmarkData {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData,
                                  options: .withSecurityScope,
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &isStale)
                if !isStale && url.startAccessingSecurityScopedResource() {
                    return url
                }
            } catch {
                print("Bookmark resolution failed: \(error)")
            }
        }
        // Fallback to direct path
        let url = URL(fileURLWithPath: localPath)
        return url
    }
    
    func fileTree(for projectID: String, localPath: String) -> [FileTreeNode] {
        guard let folderURL = accessibleFolderURL(for: projectID,
                                                  bookmarkData: nil,
                                                  localPath: localPath) else {
            return []
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        return buildFileTree(at: folderURL)
    }
    
    private func buildFileTree(at url: URL) -> [FileTreeNode] {
        func buildNode(at url: URL) -> FileTreeNode? {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            var node = FileTreeNode(url: url, isDirectory: isDirectory)
            if isDirectory {
                do {
                    let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    node.children = contents.compactMap { buildNode(at: $0) }
                } catch {
                    print("Failed to read directory: \(error)")
                }
            }
            return node
        }
        return buildNode(at: url)?.children ?? []
    }
}
