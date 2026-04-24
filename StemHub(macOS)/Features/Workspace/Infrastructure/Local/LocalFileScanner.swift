//
//  LocalFileScanner.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import CryptoKit
import Foundation

protocol FileScanner {
    nonisolated func scan(folderURL: URL) throws -> [LocalFile]
    nonisolated func makeLocalFile(from url: URL) -> LocalFile
}

struct LocalFileScanner: FileScanner {
    nonisolated func scan(folderURL: URL) throws -> [LocalFile] {
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
            let relativePath = url.path
                .replacingOccurrences(of: folderURL.path, with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            guard !relativePath.isEmpty, !url.lastPathComponent.hasPrefix(".") else { continue }

            do {
                let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let isDirectory = values.isDirectory ?? false

                if isDirectory, !FileManager.default.isReadableFile(atPath: url.path) {
                    enumerator?.skipDescendants()
                    continue
                }

                files.append(
                    LocalFile(
                        path: relativePath,
                        name: url.lastPathComponent,
                        fileExtension: url.pathExtension,
                        size: Int64(values.fileSize ?? 0),
                        hash: isDirectory ? "" : Self.hashFile(at: url),
                        isDirectory: isDirectory
                    )
                )
            } catch {
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    enumerator?.skipDescendants()
                }
            }
        }

        return files
    }

    nonisolated func makeLocalFile(from url: URL) -> LocalFile {
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

    nonisolated static func hashFile(at url: URL) -> String {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return ""
        }

        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
