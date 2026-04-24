//
//  MIDIEditorViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Combine
import Foundation

enum MIDIEditorPanel: String, CaseIterable, Identifiable {
    case notes
    case controllers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notes:
            return "Notes"
        case .controllers:
            return "Controllers"
        }
    }
}

@MainActor
final class MIDIEditorViewModel: ObservableObject {
    @Published private(set) var session: ProjectMIDISession
    @Published private(set) var document: MIDIDocument
    @Published private(set) var connectedControllers: [MIDIControllerSource] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var isRecording = false
    @Published private(set) var hasUnsavedChanges = false
    @Published private(set) var lastCaptureSummary = "Connect any CoreMIDI controller to record notes or control changes."
    @Published var selectedTrackID: UUID?
    @Published var selectedNoteID: UUID?
    @Published var selectedControllerEventID: UUID?
    @Published var activePanel: MIDIEditorPanel = .notes
    @Published var errorMessage: String?

    private let documentService: MIDIDocumentEditing
    private let controllerMonitor: MIDIControllerMonitoring

    private var monitoringSession: MIDIControllerMonitoringSession?
    private var controllerTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?
    private var recordingStartedAt: Date?
    private var activeNotes: [MIDICaptureKey: MIDICapturedNote] = [:]
    private var hasLoaded = false

    init(
        session: ProjectMIDISession,
        documentService: MIDIDocumentEditing,
        controllerMonitor: MIDIControllerMonitoring
    ) {
        self.session = session
        self.documentService = documentService
        self.controllerMonitor = controllerMonitor
        self.document = MIDIDocument.empty(
            fileURL: session.fileURL,
            relativePath: session.relativePath,
            displayName: session.displayTitle
        )
        self.selectedTrackID = document.tracks.first?.id
    }

    var tracks: [MIDITrack] {
        document.tracks
    }

    var selectedTrack: MIDITrack? {
        guard let selectedTrackID else {
            return document.tracks.first
        }

        return document.tracks.first { $0.id == selectedTrackID }
    }

    var selectedTrackNotes: [MIDINoteEvent] {
        selectedTrack?.notes.sorted { $0.startBeat < $1.startBeat } ?? []
    }

    var selectedTrackControllerEvents: [MIDIControllerEvent] {
        selectedTrack?.controllerEvents.sorted { $0.beat < $1.beat } ?? []
    }

    var selectedNote: MIDINoteEvent? {
        guard let selectedNoteID else { return nil }
        return selectedTrack?.notes.first { $0.id == selectedNoteID }
    }

    var selectedControllerEvent: MIDIControllerEvent? {
        guard let selectedControllerEventID else { return nil }
        return selectedTrack?.controllerEvents.first { $0.id == selectedControllerEventID }
    }

    var selectedTrackName: String {
        selectedTrack?.name ?? ""
    }

    var selectedTrackChannel: Int {
        Int((selectedTrack?.channel ?? 0) + 1)
    }

    var tempoBPM: Double {
        document.tempoBPM
    }

    var controllerStatusText: String {
        guard !connectedControllers.isEmpty else {
            return "No controllers connected"
        }

        let count = connectedControllers.count
        return count == 1 ? "1 controller connected" : "\(count) controllers connected"
    }

    var saveStatusText: String {
        if isSaving {
            return "Saving…"
        }

        return hasUnsavedChanges ? "Unsaved changes" : "Saved"
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }

        hasLoaded = true
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            document = try await documentService.loadDocument(from: session)
            ensureValidSelection()
            startMonitoring()
        } catch {
            hasLoaded = false
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard !isSaving else { return }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            try await documentService.saveDocument(document)
            hasUnsavedChanges = false
            lastCaptureSummary = "Saved \(document.displayName)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dispose() {
        controllerTask?.cancel()
        eventTask?.cancel()
        monitoringSession?.stop()
        monitoringSession = nil
    }

    func clearError() {
        errorMessage = nil
    }

    func selectTrack(_ trackID: UUID?) {
        selectedTrackID = trackID
        selectedNoteID = nil
        selectedControllerEventID = nil
    }

    func selectNote(_ noteID: UUID?) {
        activePanel = .notes
        selectedNoteID = noteID
        selectedControllerEventID = nil
    }

    func selectControllerEvent(_ eventID: UUID?) {
        activePanel = .controllers
        selectedControllerEventID = eventID
        selectedNoteID = nil
    }

    func addTrack() {
        let newTrack = MIDITrack.defaultTrack(index: document.tracks.count + 1)
        document.tracks.append(newTrack)
        selectTrack(newTrack.id)
        markDocumentChanged()
    }

    func removeSelectedTrack() {
        guard
            let selectedTrackID,
            document.tracks.count > 1
        else {
            return
        }

        document.tracks.removeAll { $0.id == selectedTrackID }
        ensureValidSelection()
        markDocumentChanged()
    }

    func addNote() {
        ensureTrackExists()

        guard let trackIndex = selectedTrackIndex else { return }

        let newNote = MIDINoteEvent(
            startBeat: ceil(document.tracks[trackIndex].lastEventBeat),
            durationBeats: 1,
            noteNumber: 60,
            velocity: 100,
            channel: document.tracks[trackIndex].channel
        )

        document.tracks[trackIndex].notes.append(newNote)
        normalizeTrack(at: trackIndex)
        selectNote(newNote.id)
        markDocumentChanged()
    }

    func deleteSelectedNote() {
        guard
            let trackIndex = selectedTrackIndex,
            let selectedNoteID
        else {
            return
        }

        document.tracks[trackIndex].notes.removeAll { $0.id == selectedNoteID }
        self.selectedNoteID = nil
        normalizeTrack(at: trackIndex)
        markDocumentChanged()
    }

    func addControllerEvent() {
        ensureTrackExists()

        guard let trackIndex = selectedTrackIndex else { return }

        let newEvent = MIDIControllerEvent(
            beat: ceil(document.tracks[trackIndex].lastEventBeat),
            controllerNumber: 1,
            value: 64,
            channel: document.tracks[trackIndex].channel
        )

        document.tracks[trackIndex].controllerEvents.append(newEvent)
        normalizeTrack(at: trackIndex)
        selectControllerEvent(newEvent.id)
        markDocumentChanged()
    }

    func deleteSelectedControllerEvent() {
        guard
            let trackIndex = selectedTrackIndex,
            let selectedControllerEventID
        else {
            return
        }

        document.tracks[trackIndex].controllerEvents.removeAll { $0.id == selectedControllerEventID }
        self.selectedControllerEventID = nil
        normalizeTrack(at: trackIndex)
        markDocumentChanged()
    }

    func updateSelectedTrackName(_ name: String) {
        guard let trackIndex = selectedTrackIndex else { return }
        document.tracks[trackIndex].name = name.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Track"
        markDocumentChanged()
    }

    func updateSelectedTrackChannel(_ channel: Int) {
        guard let trackIndex = selectedTrackIndex else { return }
        document.tracks[trackIndex].channel = UInt8(clamp(channel - 1, min: 0, max: 15))
        markDocumentChanged()
    }

    func updateTempo(_ tempo: Double) {
        document.tempoBPM = max(30, min(tempo, 240))
        markDocumentChanged()
    }

    func updateSelectedNoteStartBeat(_ beat: Double) {
        updateSelectedNote { note in
            note.startBeat = max(0, beat)
        }
    }

    func updateSelectedNoteDuration(_ duration: Double) {
        updateSelectedNote { note in
            note.durationBeats = max(0.25, duration)
        }
    }

    func updateSelectedNoteNumber(_ noteNumber: Int) {
        updateSelectedNote { note in
            note.noteNumber = UInt8(clamp(noteNumber, min: 0, max: 127))
        }
    }

    func updateSelectedNoteVelocity(_ velocity: Int) {
        updateSelectedNote { note in
            note.velocity = UInt8(clamp(velocity, min: 1, max: 127))
        }
    }

    func updateSelectedNoteChannel(_ channel: Int) {
        updateSelectedNote { note in
            note.channel = UInt8(clamp(channel - 1, min: 0, max: 15))
        }
    }

    func updateSelectedControllerBeat(_ beat: Double) {
        updateSelectedControllerEvent { event in
            event.beat = max(0, beat)
        }
    }

    func updateSelectedControllerNumber(_ controller: Int) {
        updateSelectedControllerEvent { event in
            event.controllerNumber = UInt8(clamp(controller, min: 0, max: 127))
        }
    }

    func updateSelectedControllerValue(_ value: Int) {
        updateSelectedControllerEvent { event in
            event.value = UInt8(clamp(value, min: 0, max: 127))
        }
    }

    func updateSelectedControllerChannel(_ channel: Int) {
        updateSelectedControllerEvent { event in
            event.channel = UInt8(clamp(channel - 1, min: 0, max: 15))
        }
    }

    func toggleRecording() {
        if isRecording {
            flushActiveNotes(at: Date())
            isRecording = false
            recordingStartedAt = nil
            lastCaptureSummary = "Recording stopped"
            return
        }

        ensureTrackExists()
        recordingStartedAt = Date()
        activeNotes.removeAll()
        isRecording = true
        lastCaptureSummary = "Recording from all available MIDI controllers"
    }

    func beatLabel(_ beat: Double) -> String {
        beat.formatted(.number.precision(.fractionLength(2)))
    }

    func channelLabel(_ channel: UInt8) -> String {
        "Ch \(Int(channel) + 1)"
    }

    func noteLabel(_ noteNumber: UInt8) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteIndex = Int(noteNumber % 12)
        let octave = (Int(noteNumber) / 12) - 1
        return "\(names[noteIndex])\(octave)"
    }
}

private extension MIDIEditorViewModel {
    var selectedTrackIndex: Int? {
        guard let selectedTrackID else { return document.tracks.indices.first }
        return document.tracks.firstIndex { $0.id == selectedTrackID }
    }

    func ensureTrackExists() {
        guard !document.tracks.isEmpty else {
            document.tracks = [.defaultTrack(index: 1)]
            selectedTrackID = document.tracks.first?.id
            return
        }

        ensureValidSelection()
    }

    func ensureValidSelection() {
        if document.tracks.isEmpty {
            selectedTrackID = nil
            selectedNoteID = nil
            selectedControllerEventID = nil
            return
        }

        if selectedTrackIndex == nil {
            selectedTrackID = document.tracks.first?.id
        }

        if selectedTrack?.notes.contains(where: { $0.id == selectedNoteID }) == false {
            selectedNoteID = nil
        }

        if selectedTrack?.controllerEvents.contains(where: { $0.id == selectedControllerEventID }) == false {
            selectedControllerEventID = nil
        }
    }

    func startMonitoring() {
        guard monitoringSession == nil else { return }

        do {
            let session = try controllerMonitor.makeMonitoringSession()
            monitoringSession = session
            controllerTask = Task { [weak self] in
                guard let self else { return }
                for await controllers in session.controllerUpdates {
                    if Task.isCancelled { break }
                    self.connectedControllers = controllers
                }
            }
            eventTask = Task { [weak self] in
                guard let self else { return }
                for await event in session.liveEvents {
                    if Task.isCancelled { break }
                    self.consume(event)
                }
            }
        } catch {
            lastCaptureSummary = error.localizedDescription
        }
    }

    func consume(_ event: MIDILiveEvent) {
        lastCaptureSummary = summary(for: event)

        guard isRecording else { return }

        switch event.message {
        case .noteOn(let noteNumber, let velocity, let channel):
            recordNoteOn(noteNumber: noteNumber, velocity: velocity, channel: channel, at: event.receivedAt)
        case .noteOff(let noteNumber, let channel):
            recordNoteOff(noteNumber: noteNumber, channel: channel, at: event.receivedAt)
        case .controlChange(let controller, let value, let channel):
            recordControllerChange(controller: controller, value: value, channel: channel, at: event.receivedAt)
        }
    }

    func recordNoteOn(noteNumber: UInt8, velocity: UInt8, channel: UInt8, at date: Date) {
        let key = MIDICaptureKey(noteNumber: noteNumber, channel: channel)
        activeNotes[key] = MIDICapturedNote(startBeat: beat(at: date), velocity: velocity)
    }

    func recordNoteOff(noteNumber: UInt8, channel: UInt8, at date: Date) {
        let key = MIDICaptureKey(noteNumber: noteNumber, channel: channel)
        guard let capturedNote = activeNotes.removeValue(forKey: key) else { return }

        let endBeat = beat(at: date)
        let duration = max(endBeat - capturedNote.startBeat, 0.25)

        updateSelectedTrack { track in
            track.notes.append(
                MIDINoteEvent(
                    startBeat: capturedNote.startBeat,
                    durationBeats: duration,
                    noteNumber: noteNumber,
                    velocity: capturedNote.velocity,
                    channel: channel
                )
            )
        }

        activePanel = .notes
    }

    func recordControllerChange(controller: UInt8, value: UInt8, channel: UInt8, at date: Date) {
        updateSelectedTrack { track in
            track.controllerEvents.append(
                MIDIControllerEvent(
                    beat: beat(at: date),
                    controllerNumber: controller,
                    value: value,
                    channel: channel
                )
            )
        }

        activePanel = .controllers
    }

    func flushActiveNotes(at date: Date) {
        let pendingNotes = activeNotes
        activeNotes.removeAll()

        for (key, value) in pendingNotes {
            let endBeat = beat(at: date)
            let duration = max(endBeat - value.startBeat, 0.25)

            updateSelectedTrack { track in
                track.notes.append(
                    MIDINoteEvent(
                        startBeat: value.startBeat,
                        durationBeats: duration,
                        noteNumber: key.noteNumber,
                        velocity: value.velocity,
                        channel: key.channel
                    )
                )
            }
        }
    }

    func beat(at date: Date) -> Double {
        guard let recordingStartedAt else { return 0 }

        let elapsedSeconds = date.timeIntervalSince(recordingStartedAt)
        return max((elapsedSeconds * document.tempoBPM) / 60, 0)
    }

    func updateSelectedNote(_ mutate: (inout MIDINoteEvent) -> Void) {
        guard let trackIndex = selectedTrackIndex else { return }
        guard let noteIndex = document.tracks[trackIndex].notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }

        mutate(&document.tracks[trackIndex].notes[noteIndex])
        normalizeTrack(at: trackIndex)
        markDocumentChanged()
    }

    func updateSelectedControllerEvent(_ mutate: (inout MIDIControllerEvent) -> Void) {
        guard let trackIndex = selectedTrackIndex else { return }
        guard let eventIndex = document.tracks[trackIndex].controllerEvents.firstIndex(where: { $0.id == selectedControllerEventID }) else { return }

        mutate(&document.tracks[trackIndex].controllerEvents[eventIndex])
        normalizeTrack(at: trackIndex)
        markDocumentChanged()
    }

    func updateSelectedTrack(_ mutate: (inout MIDITrack) -> Void) {
        guard let trackIndex = selectedTrackIndex else { return }

        mutate(&document.tracks[trackIndex])
        normalizeTrack(at: trackIndex)
        markDocumentChanged()
    }

    func normalizeTrack(at index: Int) {
        document.tracks[index].notes.sort { $0.startBeat < $1.startBeat }
        document.tracks[index].controllerEvents.sort { $0.beat < $1.beat }
        ensureValidSelection()
    }

    func markDocumentChanged() {
        hasUnsavedChanges = true
    }

    func summary(for event: MIDILiveEvent) -> String {
        switch event.message {
        case .noteOn(let noteNumber, let velocity, let channel):
            return "Note \(noteLabel(noteNumber)) on • velocity \(velocity) • \(channelLabel(channel))"
        case .noteOff(let noteNumber, let channel):
            return "Note \(noteLabel(noteNumber)) off • \(channelLabel(channel))"
        case .controlChange(let controller, let value, let channel):
            return "CC \(controller) • value \(value) • \(channelLabel(channel))"
        }
    }

    func clamp(_ value: Int, min minimum: Int, max maximum: Int) -> Int {
        Swift.max(minimum, Swift.min(value, maximum))
    }
}

private struct MIDICaptureKey: Hashable {
    let noteNumber: UInt8
    let channel: UInt8
}

private struct MIDICapturedNote {
    let startBeat: Double
    let velocity: UInt8
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
