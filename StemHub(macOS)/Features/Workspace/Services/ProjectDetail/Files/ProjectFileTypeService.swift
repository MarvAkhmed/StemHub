//
//  ProjectFileTypeService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

enum ProjectFileKind {
    case audio
    case midi
    case other
}

protocol ProjectFileTypeProviding: Sendable {
    func kind(forPath path: String) -> ProjectFileKind
    func isAudioFile(path: String) -> Bool
    func isMIDIFile(path: String) -> Bool
    func iconName(forPath path: String) -> String
}

extension ProjectFileTypeProviding {
    func kind(for url: URL) -> ProjectFileKind {
        kind(forPath: url.path)
    }

    func isAudioFile(url: URL) -> Bool {
        isAudioFile(path: url.path)
    }

    func isMIDIFile(url: URL) -> Bool {
        isMIDIFile(path: url.path)
    }

    func iconName(for url: URL) -> String {
        iconName(forPath: url.path)
    }
}

struct DefaultProjectFileTypeProvider: ProjectFileTypeProviding {
    private let mediaFileDetector: any AudioFileDetecting & MIDIFileDetecting

    init(mediaFileDetector: any AudioFileDetecting & MIDIFileDetecting) {
        self.mediaFileDetector = mediaFileDetector
    }

    func kind(forPath path: String) -> ProjectFileKind {
        let url = URL(fileURLWithPath: path)

        if mediaFileDetector.isAudioFile(url) {
            return .audio
        }

        if mediaFileDetector.isMIDIFile(url) {
            return .midi
        }

        return .other
    }

    func isAudioFile(path: String) -> Bool {
        mediaFileDetector.isAudioFile(URL(fileURLWithPath: path))
    }

    func isMIDIFile(path: String) -> Bool {
        mediaFileDetector.isMIDIFile(URL(fileURLWithPath: path))
    }

    func iconName(forPath path: String) -> String {
        switch kind(forPath: path) {
        case .audio:
            return "music.note"
        case .midi:
            return "pianokeys"
        case .other:
            return "doc"
        }
    }
}
