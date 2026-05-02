//
//  MIDIControllerInput.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

struct MIDIControllerSource: Identifiable, Equatable, Sendable {
    let id: Int32
    let name: String
    let manufacturer: String?
    let model: String?
    let isOnline: Bool

    var subtitle: String {
        let brand = [manufacturer, model]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")

        if brand.isEmpty {
            return isOnline ? "Available" : "Offline"
        }

        return isOnline ? brand : "\(brand) • Offline"
    }
}

enum MIDILiveMessage: Equatable, Sendable {
    case noteOn(noteNumber: UInt8, velocity: UInt8, channel: UInt8)
    case noteOff(noteNumber: UInt8, channel: UInt8)
    case controlChange(controller: UInt8, value: UInt8, channel: UInt8)
}

struct MIDILiveEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let sourceID: Int32?
    let receivedAt: Date
    let message: MIDILiveMessage

    init(
        id: UUID = UUID(),
        sourceID: Int32?,
        receivedAt: Date = Date(),
        message: MIDILiveMessage
    ) {
        self.id = id
        self.sourceID = sourceID
        self.receivedAt = receivedAt
        self.message = message
    }
}
