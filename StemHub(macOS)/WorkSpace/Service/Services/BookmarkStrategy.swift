//
//  DefaultBookmarkService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation

protocol BookmarkStrategy {
    func createBookmark(for url: URL) throws -> Data
}

struct DefaultBookmarkStrategy: BookmarkStrategy {
    func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
}
