//
//  UniformTypeContentTypeResolver.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 01.05.2026.
//

import Foundation
import UniformTypeIdentifiers

enum UniformTypeContentTypeResolver {
    static func contentType(for url: URL) -> UTType? {
        if let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return contentType
        }

        let pathExtension = url.pathExtension
        guard !pathExtension.isEmpty else {  return nil  }
        return UTType(filenameExtension: pathExtension)
    }
}
