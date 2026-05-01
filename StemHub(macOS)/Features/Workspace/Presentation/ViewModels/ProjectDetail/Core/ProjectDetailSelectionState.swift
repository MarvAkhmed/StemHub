//
//  ProjectDetailSelectionState.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectDetailSelectionState {
    var selectedFileURL: URL?
    var selectedFilePath: String?
    var selectedCommentTimestamp: Double?
    var midiEditorSession: ProjectMIDISession?
}
