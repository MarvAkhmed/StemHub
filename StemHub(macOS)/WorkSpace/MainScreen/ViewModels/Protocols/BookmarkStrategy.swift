//
//  BookmarkStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation

protocol BookmarkStrategy {
    func createBookmark(for url: URL) throws -> Data
}
