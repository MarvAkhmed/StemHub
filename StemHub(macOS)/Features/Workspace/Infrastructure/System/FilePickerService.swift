//
//  FilePickerService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class FilePickerService: FolderPicking, ImagePicking, AudioFilePicking {
    
    func selectFolder(title: String, message: String? = nil) async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = title
        panel.message = message ?? ""
        return panel.runModal() == .OK ? panel.url : nil
    }
    
    func selectImage() async -> NSImage? {
        let panel = NSOpenPanel()
        panel.title = "Select Project Poster"
        panel.allowedContentTypes = [.png, .jpeg]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return NSImage(contentsOf: url)
    }

    func selectAudioFiles(title: String) async -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = title
        return panel.runModal() == .OK ? panel.urls : []
    }
}
