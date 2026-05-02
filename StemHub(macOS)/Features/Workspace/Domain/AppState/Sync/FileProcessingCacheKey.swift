//
//  FileProcessingCacheKey.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

//
//  FileProcessingCache.swift
//  StemHub(macOS)
//

import Foundation

struct FileProcessingCacheKey: Sendable {
    let path: String
    let modificationDate: Date?
    let fileSize: Int64?

    nonisolated var storageKey: String {
        let mtime = modificationDate
            .map { String($0.timeIntervalSinceReferenceDate) } ?? "_"
        let size = fileSize.map(String.init) ?? "_"
        return "\(path)|\(mtime)|\(size)"
    }
}
