//
//  Array.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

import Foundation

extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async throws -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)

        for element in self {
            try Task.checkCancellation()
            if let value = try await transform(element) {
                result.append(value)
            }
        }

        return result
    }
}

extension Array where Element == URL {
    func uniqueStandardizedFileURLs() async -> [URL] {
        var seenPaths = Set<String>()
        var uniqueURLs: [URL] = []
        uniqueURLs.reserveCapacity(count)

        for url in self {
            let standardizedURL = url.standardizedFileURL
            if seenPaths.insert(standardizedURL.path).inserted {
                uniqueURLs.append(standardizedURL)
            }
        }

        return uniqueURLs
    }
}
