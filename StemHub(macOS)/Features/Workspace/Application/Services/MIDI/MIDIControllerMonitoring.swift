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

protocol MIDIControllerMonitoringSession: AnyObject {
    var controllerUpdates: AsyncStream<[MIDIControllerSource]> { get }
    var liveEvents: AsyncStream<MIDILiveEvent> { get }
    func stop()
}

final class CoreMIDIControllerMonitor: MIDIControllerMonitoring {
    func makeMonitoringSession() throws -> MIDIControllerMonitoringSession {
        try CoreMIDIControllerMonitoringSessionImpl()
    }
}

private final class CoreMIDIControllerMonitoringSessionImpl: MIDIControllerMonitoringSession {
    let controllerUpdates: AsyncStream<[MIDIControllerSource]>
    let liveEvents: AsyncStream<MIDILiveEvent>

    private let connectionQueue = DispatchQueue(label: "com.stemhub.midi.controllers")
    private let queueKey = DispatchSpecificKey<Void>()

    private var controllerContinuation: AsyncStream<[MIDIControllerSource]>.Continuation?
    private var eventContinuation: AsyncStream<MIDILiveEvent>.Continuation?

    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var connectedSources: [MIDIEndpointRef: MIDIControllerSource] = [:]
    private var isStopped = false

    init() throws {
        var controllerContinuation: AsyncStream<[MIDIControllerSource]>.Continuation?
        controllerUpdates = AsyncStream { continuation in
            controllerContinuation = continuation
        }

        var eventContinuation: AsyncStream<MIDILiveEvent>.Continuation?
        liveEvents = AsyncStream { continuation in
            eventContinuation = continuation
        }

        self.controllerContinuation = controllerContinuation
        self.eventContinuation = eventContinuation

        connectionQueue.setSpecific(key: queueKey, value: ())

        try createClient()
        try createInputPort()
        refreshSourcesAsync()
    }

    deinit {
        stop()
    }

    func stop() {
        performOnConnectionQueue {
            guard !isStopped else { return }
            isStopped = true

            for source in connectedSources.keys {
                MIDIPortDisconnectSource(inputPort, source)
            }

            connectedSources.removeAll()
            controllerContinuation?.finish()
            eventContinuation?.finish()

            if inputPort != 0 {
                MIDIPortDispose(inputPort)
                inputPort = 0
            }

            if client != 0 {
                MIDIClientDispose(client)
                client = 0
            }
        }
    }
}

private extension CoreMIDIControllerMonitoringSessionImpl {
    func createClient() throws {
        let status = MIDIClientCreateWithBlock("StemHub MIDI Monitor" as CFString, &client) { [weak self] _ in
            self?.refreshSourcesAsync()
        }

        guard status == noErr else {
            throw MIDIEditorError.controllerMonitoringFailed(status)
        }
    }

    func createInputPort() throws {
        let status = MIDIInputPortCreateWithProtocol(
            client,
            "StemHub MIDI Input" as CFString,
            ._1_0,
            &inputPort
        ) { [weak self] eventList, _ in
            self?.handleEventList(eventList)
        }

        guard status == noErr else {
            throw MIDIEditorError.controllerMonitoringFailed(status)
        }
    }

    func refreshSourcesAsync() {
        connectionQueue.async { [weak self] in
            self?.refreshSources()
        }
    }

    func refreshSources() {
        guard !isStopped else { return }

        let sources = fetchSources()
        let nextSources = Dictionary(uniqueKeysWithValues: sources.map { ($0.endpoint, $0.source) })

        for source in connectedSources.keys where nextSources[source] == nil {
            MIDIPortDisconnectSource(inputPort, source)
        }

        for source in sources where connectedSources[source.endpoint] == nil {
            MIDIPortConnectSource(inputPort, source.endpoint, nil)
        }

        connectedSources = nextSources
        controllerContinuation?.yield(
            sources.map(\.source).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        )
    }

    func fetchSources() -> [(endpoint: MIDIEndpointRef, source: MIDIControllerSource)] {
        let sourceCount = MIDIGetNumberOfSources()
        guard sourceCount > 0 else { return [] }

        var sources: [(MIDIEndpointRef, MIDIControllerSource)] = []

        for index in 0..<sourceCount {
            let endpoint = MIDIGetSource(index)
            guard endpoint != 0 else { continue }

            sources.append((endpoint, makeSource(from: endpoint)))
        }

        return sources
    }

    func makeSource(from endpoint: MIDIEndpointRef) -> MIDIControllerSource {
        let uniqueID = integerProperty(for: endpoint, key: kMIDIPropertyUniqueID)
            ?? Int32(bitPattern: endpoint)
        let name = stringProperty(for: endpoint, key: kMIDIPropertyName) ?? "MIDI Controller"
        let manufacturer = stringProperty(for: endpoint, key: kMIDIPropertyManufacturer)
        let model = stringProperty(for: endpoint, key: kMIDIPropertyModel)
        let isOffline = (integerProperty(for: endpoint, key: kMIDIPropertyOffline) ?? 0) != 0

        return MIDIControllerSource(
            id: uniqueID,
            name: name,
            manufacturer: manufacturer,
            model: model,
            isOnline: !isOffline
        )
    }

    func stringProperty(for object: MIDIObjectRef, key: CFString) -> String? {
        var value: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(object, key, &value)

        guard status == noErr, let value else {
            return nil
        }

        return value.takeRetainedValue() as String
    }

    func integerProperty(for object: MIDIObjectRef, key: CFString) -> Int32? {
        var value: Int32 = 0
        let status = MIDIObjectGetIntegerProperty(object, key, &value)
        return status == noErr ? value : nil
    }

    func handleEventList(_ eventList: UnsafePointer<MIDIEventList>) {
        let context = Unmanaged.passUnretained(self).toOpaque()
        MIDIEventListForEachEvent(eventList, midiEventVisitor, context)
    }

    func emit(_ event: MIDILiveEvent) {
        guard !isStopped else { return }
        eventContinuation?.yield(event)
    }

    func performOnConnectionQueue(_ work: () -> Void) {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            work()
        } else {
            connectionQueue.sync(execute: work)
        }
    }
}

private func midiEventVisitor(
    context: UnsafeMutableRawPointer?,
    timeStamp: MIDITimeStamp,
    message: MIDIUniversalMessage
) {
    guard let context else { return }

    let session = Unmanaged<CoreMIDIControllerMonitoringSessionImpl>
        .fromOpaque(context)
        .takeUnretainedValue()

    if let event = makeLiveEvent(from: message, timeStamp: timeStamp) {
        session.emit(event)
    }
}

private func makeLiveEvent(
    from message: MIDIUniversalMessage,
    timeStamp: MIDITimeStamp
) -> MIDILiveEvent? {
    switch message.type {
    case .channelVoice1:
        return makeLiveEventFromChannelVoice1(message, timeStamp: timeStamp)
    case .channelVoice2:
        return makeLiveEventFromChannelVoice2(message, timeStamp: timeStamp)
    default:
        return nil
    }
}

private func makeLiveEventFromChannelVoice1(
    _ message: MIDIUniversalMessage,
    timeStamp: MIDITimeStamp
) -> MIDILiveEvent? {
    let channelMessage = message.channelVoice1

    switch channelMessage.status {
    case .noteOn:
        if channelMessage.note.velocity == 0 {
            return MIDILiveEvent(
                sourceID: nil,
                receivedAt: Date(),
                message: .noteOff(noteNumber: channelMessage.note.number, channel: channelMessage.channel)
            )
        }

        return MIDILiveEvent(
            sourceID: nil,
            receivedAt: Date(),
            message: .noteOn(
                noteNumber: channelMessage.note.number,
                velocity: channelMessage.note.velocity,
                channel: channelMessage.channel
            )
        )
    case .noteOff:
        return MIDILiveEvent(
            sourceID: nil,
            receivedAt: Date(),
            message: .noteOff(noteNumber: channelMessage.note.number, channel: channelMessage.channel)
        )
    case .controlChange:
        return MIDILiveEvent(
            sourceID: nil,
            receivedAt: Date(),
            message: .controlChange(
                controller: channelMessage.controlChange.index,
                value: channelMessage.controlChange.data,
                channel: channelMessage.channel
            )
        )
    default:
        return nil
    }
}

private func makeLiveEventFromChannelVoice2(
    _ message: MIDIUniversalMessage,
    timeStamp: MIDITimeStamp
) -> MIDILiveEvent? {
    let channelMessage = message.channelVoice2

    switch channelMessage.status {
    case .noteOn:
        let velocity = UInt8(min(channelMessage.note.velocity >> 8, 127))
        if velocity == 0 {
            return MIDILiveEvent(
                sourceID: nil,
                receivedAt: Date(),
                message: .noteOff(noteNumber: channelMessage.note.number, channel: channelMessage.channel)
            )
        }

        return MIDILiveEvent(
            sourceID: nil,
            receivedAt: Date(),
            message: .noteOn(
                noteNumber: channelMessage.note.number,
                velocity: velocity,
                channel: channelMessage.channel
            )
        )
    case .noteOff:
        return MIDILiveEvent(
            sourceID: nil,
            receivedAt: Date(),
            message: .noteOff(noteNumber: channelMessage.note.number, channel: channelMessage.channel)
        )
    case .controlChange:
        return MIDILiveEvent(
            sourceID: nil,
            receivedAt: Date(),
            message: .controlChange(
                controller: channelMessage.controlChange.index,
                value: UInt8(min(channelMessage.controlChange.data >> 25, 127)),
                channel: channelMessage.channel
            )
        )
    default:
        return nil
    }
}
