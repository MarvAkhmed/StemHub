//
//  WorkspacePickerProtocols.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import AppKit
import Foundation

@MainActor
protocol FolderPicking {
    func selectFolder(title: String, message: String?) async -> URL?
}

@MainActor
protocol ImagePicking {
    func selectImage() async -> NSImage?
}

@MainActor
protocol AudioFilePicking {
    func selectAudioFiles(title: String) async -> [URL]
}
