//
//  PosterEncodingError.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 23.04.2026.
//

import AppKit

enum PosterEncodingError: LocalizedError {
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid Image"
        }
    }
}
