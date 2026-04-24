//
//  CreateProjectFolderMetadata.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct CreateProjectFolderMetadata: Equatable {
    let folderName: String
    let folderPath: String
    let subfolderCount: Int
    let totalFileCount: Int
    let audioFileCount: Int
    let midiFileCount: Int
    let totalBytes: Int64
    let lastModifiedAt: Date?

    var nonAudioFileCount: Int {
        max(0, totalFileCount - audioFileCount - midiFileCount)
    }

    var totalSizeDescription: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    var lastModifiedDescription: String {
        guard let lastModifiedAt else { return "Unknown" }
        return lastModifiedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
