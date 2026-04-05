//
//  LocalFileScanner.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import CryptoKit

struct LocalFileScanner: FileScanStrategy {
    func scan(folderURL: URL) throws -> [LocalFile] {
        var files: [LocalFile] = []
        
        let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        
        while let url = enumerator?.nextObject() as? URL {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            let isDirectory = values.isDirectory ?? false
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
        }
        
        return files
    }
    
    private static func hashFile(at url: URL) -> String {
        guard let data = try? Data(contentsOf: url) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
