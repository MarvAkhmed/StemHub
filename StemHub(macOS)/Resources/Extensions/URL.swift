//
//  URL.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 01.05.2026.
//

import Foundation

extension URL {
    nonisolated func withSecurityScopedAccess<T>(operation: () throws -> T) rethrows -> T {
        let didStartAccess = startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }

    nonisolated func withSecurityScopedAccess<T>(operation: () async throws -> T) async rethrows -> T {
        let didStartAccess = startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                stopAccessingSecurityScopedResource()
            }
        }

        return try await operation()
    }
}
