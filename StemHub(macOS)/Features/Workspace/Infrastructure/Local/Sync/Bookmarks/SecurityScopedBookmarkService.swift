//
//  SecurityScopedBookmarkService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol BookmarkStrategy: Sendable {
    nonisolated func createBookmark(for url: URL) throws -> Data
    nonisolated func resolveBookmark(_ data: Data) throws -> ResolvedBookmark
}

struct DefaultBookmarkStrategy: BookmarkStrategy {
    nonisolated func createBookmark(for url: URL) throws -> Data {
        let data = try url.bookmarkData(options: .withSecurityScope,
                                       includingResourceValuesForKeys: nil,
                                       relativeTo: nil)
        return data
    }

    nonisolated func resolveBookmark(_ data: Data) throws -> ResolvedBookmark {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return ResolvedBookmark(url: url, isStale: isStale)
    }
}
