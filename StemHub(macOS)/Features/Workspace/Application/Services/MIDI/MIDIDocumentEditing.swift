//
//  MIDIDocumentEditing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import AudioToolbox
import Foundation

protocol MIDIDocumentEditing {
    func loadDocument(from session: ProjectMIDISession) async throws -> MIDIDocument
    func saveDocument(_ document: MIDIDocument) async throws
}

struct CoreAudioMIDIDocumentService: MIDIDocumentEditing {
    func loadDocument(from session: ProjectMIDISession) async throws -> MIDIDocument {
        try await Task.detached(priority: .userInitiated) {
            try MIDIDocumentIO.loadDocumentSynchronously(from: session)
        }.value
    }

    func saveDocument(_ document: MIDIDocument) async throws {
        try await Task.detached(priority: .utility) {
            try MIDIDocumentIO.saveDocumentSynchronously(document)
        }.value
    }
}

private enum MIDIDocumentIO {
    nonisolated static func loadDocumentSynchronously(from session: ProjectMIDISession) throws -> MIDIDocument {
        guard FileManager.default.fileExists(atPath: session.fileURL.path) else {
            return MIDIDocument.empty(
                fileURL: session.fileURL,
                relativePath: session.relativePath,
                displayName: session.displayTitle
            )
        }

        return try withScopedAccess(to: session.fileURL) {
            var sequence: MusicSequence?
            try requireNoErr(NewMusicSequence(&sequence), error: { .loadFailed($0) })

            guard let sequence else {
                throw MIDIEditorError.invalidMIDIDocument
            }

            defer { DisposeMusicSequence(sequence) }

            try requireNoErr(
                MusicSequenceFileLoad(
                    sequence,
                    session.fileURL as CFURL,
                    .midiType,
                    MusicSequenceLoadFlags(rawValue: 0)
                ),
                error: { .loadFailed($0) }
            )

            let tempo = try extractTempo(from: sequence)
            let tracks = try extractTracks(from: sequence)

            return MIDIDocument(
                fileURL: session.fileURL,
                relativePath: session.relativePath,
                displayName: session.displayTitle,
                tempoBPM: tempo,
                tracks: tracks.isEmpty ? [.defaultTrack(index: 1)] : tracks
            )
        }
    }

    nonisolated static func saveDocumentSynchronously(_ document: MIDIDocument) throws {
        try withScopedAccess(to: document.fileURL.deletingLastPathComponent()) {
            try FileManager.default.createDirectory(
                at: document.fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            var sequence: MusicSequence?
            try requireNoErr(NewMusicSequence(&sequence), error: { .saveFailed($0) })

            guard let sequence else {
                throw MIDIEditorError.invalidMIDIDocument
            }

            defer { DisposeMusicSequence(sequence) }

            try addTempoTrack(to: sequence, bpm: document.tempoBPM)
            try addTracks(document.tracks, to: sequence)

            try requireNoErr(
                MusicSequenceFileCreate(
                    sequence,
                    document.fileURL as CFURL,
                    .midiType,
                    .eraseFile,
                    480
                ),
                error: { .saveFailed($0) }
            )
        }
    }

    nonisolated static func extractTempo(from sequence: MusicSequence) throws -> Double {
        var tempoTrack: MusicTrack?
        try requireNoErr(MusicSequenceGetTempoTrack(sequence, &tempoTrack), error: { .loadFailed($0) })

        guard let tempoTrack else { return 120 }
        return try firstTempoValue(in: tempoTrack) ?? 120
    }

    nonisolated static func firstTempoValue(in track: MusicTrack) throws -> Double? {
        var iterator: MusicEventIterator?
        try requireNoErr(NewMusicEventIterator(track, &iterator), error: { .loadFailed($0) })

        guard let iterator else { return nil }
        defer { DisposeMusicEventIterator(iterator) }

        var hasEvent = DarwinBoolean(false)
        MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)

        while hasEvent.boolValue {
            var eventType: MusicEventType = 0
            var eventTime: MusicTimeStamp = 0
            var eventData: UnsafeRawPointer?
            var eventSize: UInt32 = 0

            try requireNoErr(
                MusicEventIteratorGetEventInfo(
                    iterator,
                    &eventTime,
                    &eventType,
                    &eventData,
                    &eventSize
                ),
                error: { .loadFailed($0) }
            )

            if eventType == 3,
               let tempoEvent = eventData?.assumingMemoryBound(to: ExtendedTempoEvent.self).pointee {
                return tempoEvent.bpm
            }

            MusicEventIteratorNextEvent(iterator)
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
        }

        return nil
    }

    nonisolated static func extractTracks(from sequence: MusicSequence) throws -> [MIDITrack] {
        var trackCount: UInt32 = 0
        try requireNoErr(MusicSequenceGetTrackCount(sequence, &trackCount), error: { .loadFailed($0) })

        var tracks: [MIDITrack] = []

        for index in 0..<trackCount {
            var track: MusicTrack?
            try requireNoErr(MusicSequenceGetIndTrack(sequence, index, &track), error: { .loadFailed($0) })

            guard let track else { continue }
            tracks.append(try extractTrack(track, at: Int(index)))
        }

        return tracks
    }

    nonisolated static func extractTrack(_ track: MusicTrack, at index: Int) throws -> MIDITrack {
        var iterator: MusicEventIterator?
        try requireNoErr(NewMusicEventIterator(track, &iterator), error: { .loadFailed($0) })

        guard let iterator else {
            return .defaultTrack(index: index + 1)
        }

        defer { DisposeMusicEventIterator(iterator) }

        var notes: [MIDINoteEvent] = []
        var controllerEvents: [MIDIControllerEvent] = []
        var inferredChannel = UInt8(index % 16)

        var hasEvent = DarwinBoolean(false)
        MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)

        while hasEvent.boolValue {
            var eventType: MusicEventType = 0
            var eventTime: MusicTimeStamp = 0
            var eventData: UnsafeRawPointer?
            var eventSize: UInt32 = 0

            try requireNoErr(
                MusicEventIteratorGetEventInfo(
                    iterator,
                    &eventTime,
                    &eventType,
                    &eventData,
                    &eventSize
                ),
                error: { .loadFailed($0) }
            )

            if eventType == 6,
               let note = eventData?.assumingMemoryBound(to: MIDINoteMessage.self).pointee {
                inferredChannel = note.channel
                notes.append(
                    MIDINoteEvent(
                        startBeat: eventTime,
                        durationBeats: max(Double(note.duration), 0.25),
                        noteNumber: note.note,
                        velocity: note.velocity,
                        channel: note.channel
                    )
                )
            } else if eventType == 7,
                      let message = eventData?.assumingMemoryBound(to: MIDIChannelMessage.self).pointee,
                      (message.status & 0xF0) == 0xB0 {
                inferredChannel = message.status & 0x0F
                controllerEvents.append(
                    MIDIControllerEvent(
                        beat: eventTime,
                        controllerNumber: message.data1,
                        value: message.data2,
                        channel: message.status & 0x0F
                    )
                )
            }

            MusicEventIteratorNextEvent(iterator)
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
        }

        return MIDITrack(
            name: "Track \(index + 1)",
            channel: inferredChannel,
            notes: notes.sorted { $0.startBeat < $1.startBeat },
            controllerEvents: controllerEvents.sorted { $0.beat < $1.beat }
        )
    }

    nonisolated static func addTempoTrack(to sequence: MusicSequence, bpm: Double) throws {
        var tempoTrack: MusicTrack?
        try requireNoErr(MusicSequenceGetTempoTrack(sequence, &tempoTrack), error: { .saveFailed($0) })

        guard let tempoTrack else { return }
        try requireNoErr(
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, bpm),
            error: { .saveFailed($0) }
        )
    }

    nonisolated static func addTracks(_ tracks: [MIDITrack], to sequence: MusicSequence) throws {
        for track in tracks {
            var musicTrack: MusicTrack?
            try requireNoErr(MusicSequenceNewTrack(sequence, &musicTrack), error: { .saveFailed($0) })

            guard let musicTrack else { continue }
            try addEvents(of: track, to: musicTrack)
        }
    }

    nonisolated static func addEvents(of track: MIDITrack, to musicTrack: MusicTrack) throws {
        for note in track.notes.sorted(by: { $0.startBeat < $1.startBeat }) {
            var message = MIDINoteMessage(
                channel: note.channel,
                note: note.noteNumber,
                velocity: note.velocity,
                releaseVelocity: 0,
                duration: Float32(max(note.durationBeats, 0.25))
            )

            try requireNoErr(
                MusicTrackNewMIDINoteEvent(musicTrack, note.startBeat, &message),
                error: { .saveFailed($0) }
            )
        }

        for controllerEvent in track.controllerEvents.sorted(by: { $0.beat < $1.beat }) {
            var message = MIDIChannelMessage(
                status: 0xB0 | controllerEvent.channel,
                data1: controllerEvent.controllerNumber,
                data2: controllerEvent.value,
                reserved: 0
            )

            try requireNoErr(
                MusicTrackNewMIDIChannelEvent(musicTrack, controllerEvent.beat, &message),
                error: { .saveFailed($0) }
            )
        }
    }

    nonisolated static func requireNoErr(
        _ status: OSStatus,
        error errorBuilder: (OSStatus) -> MIDIEditorError
    ) throws {
        guard status == noErr else {
            throw errorBuilder(status)
        }
    }

    nonisolated static func withScopedAccess<T>(to url: URL, operation: () throws -> T) rethrows -> T {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }
}
