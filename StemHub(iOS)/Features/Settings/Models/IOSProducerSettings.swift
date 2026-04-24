//
//  IOSProducerSettings.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum IOSProducerExportFormat: String, CaseIterable, Codable, Sendable {
    case wav
    case mp3

    var title: String {
        rawValue.uppercased()
    }
}

struct IOSProducerSettings: Codable, Sendable {
    var defaultPlaybackRate: Double
    var highlightCommentMarkers: Bool
    var autoRefreshInbox: Bool
    var compactReviewSidebar: Bool
    var keepInlinePlayersArmed: Bool
    var notificationAlertsEnabled: Bool
    var preferredExportFormat: IOSProducerExportFormat

    static let `default` = IOSProducerSettings(
        defaultPlaybackRate: 1.0,
        highlightCommentMarkers: true,
        autoRefreshInbox: true,
        compactReviewSidebar: false,
        keepInlinePlayersArmed: true,
        notificationAlertsEnabled: true,
        preferredExportFormat: .wav
    )
}

protocol IOSProducerSettingsReading {
    func load() -> IOSProducerSettings
}

protocol IOSProducerSettingsWriting {
    func save(_ settings: IOSProducerSettings)
}

typealias IOSProducerSettingsStoring = IOSProducerSettingsReading & IOSProducerSettingsWriting

struct UserDefaultsIOSProducerSettingsStore: IOSProducerSettingsStoring {
    private let defaults: UserDefaults
    private let key = "ios_producer_settings_v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> IOSProducerSettings {
        guard
            let data = defaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(IOSProducerSettings.self, from: data)
        else {
            return .default
        }

        return settings
    }

    func save(_ settings: IOSProducerSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
