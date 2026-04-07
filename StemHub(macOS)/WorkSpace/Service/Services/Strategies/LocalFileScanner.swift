//
//  LocalFileScanner.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import CryptoKit

protocol FileScanStrategy {
    func scan(folderURL: URL) throws -> [LocalFile]
    func makeLocalFile(from url: URL) -> LocalFile
}

struct LocalFileScanner: FileScanStrategy {
    func scan(folderURL: URL) throws -> [LocalFile] {
        var files: [LocalFile] = []
        
        let didStartAccess = folderURL.startAccessingSecurityScopedResource()
        
        defer {
            if didStartAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        
        while let url = enumerator?.nextObject() as? URL {
            do {
                let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let isDirectory = values.isDirectory ?? false
                
                // Skip directories we can't read
                if isDirectory {
                    // Check if directory is readable
                    if !FileManager.default.isReadableFile(atPath: url.path) {
                        print("⚠️ Skipping unreadable directory: \(url.path)")
                        enumerator?.skipDescendants()
                        continue
                    }
                }
                
                let relativePath = url.path.replacingOccurrences(of: folderURL.path, with: "")
                
                guard !url.lastPathComponent.hasPrefix(".") else { continue }
                
                let file = LocalFile(
                    path: relativePath,
                    name: url.lastPathComponent,
                    fileExtension: url.pathExtension,
                    size: Int64(values.fileSize ?? 0),
                    hash: isDirectory ? "" : Self.hashFile(at: url),
                    isDirectory: isDirectory
                )
                
                files.append(file)
            } catch {
                // Log but don't crash - skip this file/directory
                print("⚠️ Failed to read file at \(url.path): \(error.localizedDescription)")
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    enumerator?.skipDescendants()
                }
                continue
            }
        }
        return files
    }
    
    func makeLocalFile(from url: URL) -> LocalFile {
        // Ensure security-scoped access before reading
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let hash = Self.hashFile(at: url)
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        return LocalFile(
            path: url.lastPathComponent,
            name: url.lastPathComponent,
            fileExtension: url.pathExtension,
            size: size,
            hash: hash,
            isDirectory: false
        )
    }
    
    static func hashFile(at url: URL) -> String {
        // Ensure security-scoped access before reading
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ Failed to read file for hashing: \(url.path)")
            return ""
        }
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
