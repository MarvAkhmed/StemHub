//
//  LocalFileScanner.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol FileScannerStrategy: Sendable {
    nonisolated func fileURLs(in folderURL: URL) throws -> [URL]
    nonisolated func fileTree(folderURL: URL) throws -> [FileTreeNode]
    nonisolated func relativePath(for url: URL, in folderURL: URL) -> String?
}

struct LocalFileScanner: FileScannerStrategy {
    nonisolated func fileURLs(in folderURL: URL) throws -> [URL] {
        try folderURL.withSecurityScopedAccess {
            try scanAccessibleFolder(folderURL)
        }
    }
    
    nonisolated func fileTree(folderURL: URL) throws -> [FileTreeNode] {
        folderURL.withSecurityScopedAccess {
            buildFileTree(at: folderURL)
        }
    }
    
    nonisolated func relativePath(for url: URL, in folderURL: URL) -> String? {
        let rootPath = folderURL.standardizedFileURL.path
        let filePath = url.standardizedFileURL.path
        
        guard filePath == rootPath ||
              filePath.hasPrefix(rootPath + "/")
        else { return nil }
        
        let path = filePath
            .replacingOccurrences(of: rootPath, with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        return path.isEmpty ? nil : path
    }
}

// scanner helpers
private extension LocalFileScanner {
    nonisolated func scanAccessibleFolder(_ folderURL: URL) throws -> [URL] {
        var files: [URL] = []
        let enumerator = makeEnumerator(for: folderURL)
        
        while let url = enumerator?.nextObject() as? URL {
            guard let relativePath = relativePath(for: url, in: folderURL),
                  shouldInclude(url: url, relativePath: relativePath)
            else { continue }
            
            if let fileURL = try scannedFileURL(from: url, enumerator: enumerator) {
                files.append(fileURL)
            }
        }
        return files
    }
    
    nonisolated func makeEnumerator(for folderURL: URL) -> FileManager.DirectoryEnumerator? {
        return FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
    }
    
    nonisolated func shouldInclude(url: URL, relativePath: String) -> Bool {
        !relativePath.isEmpty && !url.lastPathComponent.hasPrefix(".")
    }
    
    nonisolated func scannedFileURL(from url: URL, enumerator: FileManager.DirectoryEnumerator?)throws -> URL? {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
        let isDirectory = values.isDirectory ?? false
        
        guard !isDirectory else {
            if !FileManager.default.isReadableFile(atPath: url.path) {
                enumerator?.skipDescendants()
            }
            return nil
        }
        
        return url
    }
    
    nonisolated func buildFileTree(at url: URL) -> [FileTreeNode] {
        func buildNode(at nodeURL: URL) -> FileTreeNode? {
            let sKeys: Set<URLResourceKey> = [.isDirectoryKey]
            let keys: [URLResourceKey] =  [.isDirectoryKey]
            
            let isDirectory = (try? nodeURL.resourceValues(forKeys: sKeys))?.isDirectory ?? false
            
            var node = FileTreeNode(url: nodeURL, isDirectory: isDirectory)
            
            let contentsOfDirectory = try? FileManager.default.contentsOfDirectory(
                at: nodeURL,
                includingPropertiesForKeys: keys
            )
            
            if isDirectory {
                let contents = (contentsOfDirectory) ?? []
                node.children = contents.compactMap(buildNode)
            }
            
            return node
        }
        return buildNode(at: url)?.children ?? []
    }
}
