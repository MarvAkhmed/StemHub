//
//  UniformTypeContentTypeResolver.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation
import UniformTypeIdentifiers

/// Pure namespace for resolving the `UTType` of a file URL.
///
/// LAW-D1: Caseless enum — prevents instantiation, holds no static stored state.
/// LAW-N1: One primary type per file.
///
/// ## Resolution strategy
/// 1. Attempt to read the file system's `contentTypeKey` resource value.
///    This is the most accurate source because it reflects the actual file data.
/// 2. Fall back to inferring the type from the URL's path extension.
///    This handles cases where the file does not yet exist on disk (e.g. a
///    URL constructed from user input before the file is written).
enum UniformTypeContentTypeResolver {

    /// Returns the `UTType` for the file at `url`, or `nil` if the type
    /// cannot be determined.
    ///
    /// - Parameter url: The file URL to inspect.
    /// - Returns: A `UTType` value, or `nil` if neither the file system
    ///   resource key nor the path extension yields a result.
    static func contentType(for url: URL) -> UTType? {
        // Attempt 1: Read from the file system resource values.
        // `try?` is acceptable here — a failure falls through to the extension
        // fallback and the `nil` result is explicitly handled by the caller.
        if let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return contentType
        }

        // Attempt 2: Infer from path extension.
        let pathExtension = url.pathExtension
        guard !pathExtension.isEmpty else { return nil }
        return UTType(filenameExtension: pathExtension)
    }
}
