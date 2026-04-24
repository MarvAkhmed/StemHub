//
//  MIDIEditorError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum MIDIEditorError: LocalizedError {
    case invalidMIDIDocument
    case loadFailed(OSStatus)
    case saveFailed(OSStatus)
    case controllerMonitoringFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidMIDIDocument:
            return "StemHub could not read this MIDI file."
        case .loadFailed(let status):
            return "StemHub could not open this MIDI file. (OSStatus: \(status))"
        case .saveFailed(let status):
            return "StemHub could not save the MIDI file. (OSStatus: \(status))"
        case .controllerMonitoringFailed(let status):
            return "StemHub could not connect to MIDI controllers. (OSStatus: \(status))"
        }
    }
}
