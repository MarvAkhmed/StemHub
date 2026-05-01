//
//  AudioAnalysisImplementationError.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation


enum AudioAnalysisImplementationError: LocalizedError {
    case notImplemented(String)
    case missingDomainModel(String)
    case decodeFailed(String)
    case invalidFingerprint(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .notImplemented(let message),
             .missingDomainModel(let message),
             .decodeFailed(let message),
             .invalidFingerprint(let message):
            return message
        }
    }
}
