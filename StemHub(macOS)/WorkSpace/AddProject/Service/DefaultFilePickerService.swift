//
//  DefaultFilePickerService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

final class DefaultFilePickerService: FilePickerService {
    
    @MainActor
    func selectFolder() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }
    
    @MainActor
    func selectImage() async -> NSImage? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return NSImage(contentsOf: url)
    }
}
