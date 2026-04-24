//
//  MIDIDocument.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

struct MIDIDocument: Identifiable, Equatable, Sendable {
    let id: UUID
    var fileURL: URL
    var relativePath: String
    var displayName: String
    var tempoBPM: Double
    var tracks: [MIDITrack]

    nonisolated init(
        id: UUID = UUID(),
        fileURL: URL,
        relativePath: String,
        displayName: String,
        tempoBPM: Double,
        tracks: [MIDITrack]
    ) {
        self.id = id
        self.fileURL = fileURL
        self.relativePath = relativePath
        self.displayName = displayName
        self.tempoBPM = tempoBPM
        self.tracks = tracks
    }

    nonisolated static func empty(
        fileURL: URL,
        relativePath: String,
        displayName: String
    ) -> MIDIDocument {
        MIDIDocument(
            fileURL: fileURL,
            relativePath: relativePath,
            displayName: displayName,
            tempoBPM: 120,
            tracks: [.defaultTrack(index: 1)]
        )
    }

    nonisolated var totalBeats: Double {
        max(tracks.map(\.lastEventBeat).max() ?? 0, 4)
    }
}

struct MIDITrack: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var channel: UInt8
    var notes: [MIDINoteEvent]
    var controllerEvents: [MIDIControllerEvent]

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        channel: UInt8,
        notes: [MIDINoteEvent],
        controllerEvents: [MIDIControllerEvent]
    ) {
        self.id = id
        self.name = name
        self.channel = channel
        self.notes = notes
        self.controllerEvents = controllerEvents
    }

    nonisolated static func defaultTrack(index: Int) -> MIDITrack {
        MIDITrack(
            name: "Track \(index)",
            channel: UInt8((index - 1) % 16),
            notes: [],
            controllerEvents: []
        )
    }

    nonisolated var lastEventBeat: Double {
        let noteEndBeat = notes.map { $0.startBeat + $0.durationBeats }.max() ?? 0
        let controllerBeat = controllerEvents.map(\.beat).max() ?? 0
        return max(noteEndBeat, controllerBeat)
    }
}

struct MIDINoteEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    var startBeat: Double
    var durationBeats: Double
    var noteNumber: UInt8
    var velocity: UInt8
    var channel: UInt8

    nonisolated init(
        id: UUID = UUID(),
        startBeat: Double,
        durationBeats: Double,
        noteNumber: UInt8,
        velocity: UInt8,
        channel: UInt8
    ) {
        self.id = id
        self.startBeat = startBeat
        self.durationBeats = durationBeats
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.channel = channel
    }
}

struct MIDIControllerEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    var beat: Double
    var controllerNumber: UInt8
    var value: UInt8
    var channel: UInt8

    nonisolated init(
        id: UUID = UUID(),
        beat: Double,
        controllerNumber: UInt8,
        value: UInt8,
        channel: UInt8
    ) {
        self.id = id
        self.beat = beat
        self.controllerNumber = controllerNumber
        self.value = value
        self.channel = channel
    }
}
