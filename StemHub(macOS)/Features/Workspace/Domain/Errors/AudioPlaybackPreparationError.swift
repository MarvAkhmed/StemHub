//
//  AudioPlaybackPreparationError.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

enum AudioPlaybackPreparationError: LocalizedError {
    case unreadableFile
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "StemHub could not read this file from disk."
        case .unsupportedFormat:
            return "This audio file format cannot be previewed inline."
        }
    }
}
