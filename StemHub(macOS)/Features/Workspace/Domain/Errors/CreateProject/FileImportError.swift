//
//  FileImportError.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 01.05.2026.
//

import Foundation

enum FileImportError: LocalizedError {
    case destinationAlreadyExists(URL)
    case destinationOutsideWorkingDirectory(URL)

    var errorDescription: String? {
        switch self {
        case let .destinationAlreadyExists(url):
            return "A file already exists at \(url.path)."
        case let .destinationOutsideWorkingDirectory(url):
            return "The import destination is outside the working directory: \(url.path)."
        }
    }
}
