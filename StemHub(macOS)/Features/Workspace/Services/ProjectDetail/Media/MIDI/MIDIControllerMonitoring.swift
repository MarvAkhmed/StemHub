//
//  MIDIControllerMonitoring.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import CoreMIDI
import Foundation

protocol MIDIControllerMonitoring {
    func makeMonitoringSession() throws -> MIDIControllerMonitoringSession
}


final class CoreMIDIControllerMonitor: MIDIControllerMonitoring {
    func makeMonitoringSession() throws -> MIDIControllerMonitoringSession {
        try CoreMIDIControllerMonitoringSessionImpl()
    }
}

