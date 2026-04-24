//
//  SecurityScopedBookmarkService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol BookmarkStrategy {
    nonisolated func createBookmark(for url: URL) throws -> Data
    nonisolated func resolveBookmark(_ data: Data) throws -> URL
}

struct DefaultBookmarkStrategy: BookmarkStrategy {
    nonisolated func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    nonisolated func resolveBookmark(_ data: Data) throws -> URL {
        var isStale = false
        return try URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }
}
