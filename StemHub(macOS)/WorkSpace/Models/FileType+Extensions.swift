//
//  FileType+Extensions.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//


import Foundation
import SwiftUI

extension FileType {
    var iconName: String {
        switch self {
        case .audio:
            return "music.note"
        case .midi:
            return "pianokeys"
        case .project:
            return "doc.badge.gearshape"
        case .folder:
            return "folder"
        case .other:
            return "doc"
        }
    }
    
    var color: Color {
        switch self {
        case .audio:
            return .blue
        case .midi:
            return .purple
        case .project:
            return .orange
        case .folder:
            return .gray
        case .other:
            return .secondary
        }
    }
}

// Helper to detect FileType from file extension
extension FileType {
    static func from(fileExtension: String) -> FileType {
        let ext = fileExtension.lowercased()
        
        switch ext {
        case "mp3", "wav", "aac", "m4a", "flac", "ogg", "wma":
            return .audio
        case "mid", "midi", "smf":
            return .midi
        case "stemhub", "project", "stm":
            return .project
        default:
            return .other
        }
    }
}
