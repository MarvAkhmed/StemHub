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
                
                if isStale {
                    print("⚠️ Bookmark is stale for project: \(projectID)")
                    // Don't return nil - fall back to localPath
                    let fallbackURL = URL(fileURLWithPath: localPath)
                    if FileManager.default.isReadableFile(atPath: fallbackURL.path) {
                        return fallbackURL
                    }
                    return nil
                }
                
                // Verify we can actually access this URL
                if url.startAccessingSecurityScopedResource() {
                    url.stopAccessingSecurityScopedResource() // Caller will start their own access
                    return url
                } else {
                    print("⚠️ Cannot access security-scoped resource for project: \(projectID)")
                    // Fall back to direct path
                    let fallbackURL = URL(fileURLWithPath: localPath)
                    if FileManager.default.isReadableFile(atPath: fallbackURL.path) {
                        return fallbackURL
                    }
                    return nil
                }
            } catch {
                print("❌ Bookmark resolution error: \(error)")
                // Fall back to direct path
                let fallbackURL = URL(fileURLWithPath: localPath)
                if FileManager.default.isReadableFile(atPath: fallbackURL.path) {
                    return fallbackURL
                }
                return nil
            }
        }
        
        // No bookmark, try direct path
        let url = URL(fileURLWithPath: localPath)
        if FileManager.default.isReadableFile(atPath: url.path) {
            return url
        }
        
        return nil
    }
    
    func fileTree(for projectID: String, localPath: String) -> [FileTreeNode] {
        // Try to get bookmark data first
        let bookmarkData = UserDefaults.standard.data(forKey: "project_\(projectID)_bookmark")
        
        guard let folderURL = accessibleFolderURL(for: projectID,
                                                    bookmarkData: bookmarkData,
                                                    localPath: localPath) else {
            print(" Cannot access folder for project: \(projectID)")
            return []
        }
        
        let didStartAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }
        
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
