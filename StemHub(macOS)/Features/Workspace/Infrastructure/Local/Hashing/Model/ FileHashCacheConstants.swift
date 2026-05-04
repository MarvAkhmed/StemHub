//
//   FileHashCacheConstants.swift.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 04.05.2026.
//

import Foundation

enum FileHashCacheConstants {
    static let algorithmVersion = "sha256-v1"
    static let defaultMaxEntries = 200_000
}

enum FileHashCacheEntity {
    static let name = "FileHashCacheEntry"
}

enum FileHashCacheKey {
    static let cacheKey = "cacheKey"
    static let fileHash = "fileHash"
    static let algorithmVersion = "algorithmVersion"
    static let lastAccessedAt = "lastAccessedAt"
    static let createdAt = "createdAt"
    static let fileSize = "fileSize"
    static let modifiedAt = "modifiedAt"
}
