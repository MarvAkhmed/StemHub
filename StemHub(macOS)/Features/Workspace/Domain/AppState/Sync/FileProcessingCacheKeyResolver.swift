//
//  FileProcessingCacheKeyResolver.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

import Foundation

enum FileProcessingCacheKeyResolver {

    nonisolated static func key(for url: URL) throws -> FileProcessingCacheKey {
        let resourceKeys: Set<URLResourceKey> = [
            .contentModificationDateKey,
            .fileSizeKey,
        ]
        let values = try url.resourceValues(forKeys: resourceKeys)

        return FileProcessingCacheKey(
            path: url.standardizedFileURL.path,
            modificationDate: values.contentModificationDate,
            fileSize: values.fileSize.map(Int64.init)
        )
    }
}
