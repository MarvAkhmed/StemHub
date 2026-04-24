//
//  ProducerSettings.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum ProducerExportFormat: String, CaseIterable, Codable, Sendable {
    case wav
    case mp3

    var title: String {
        rawValue.uppercased()
    }
}

struct ProducerSettings: Codable, Sendable {
    var defaultPlaybackRate: Double
    var highlightCommentMarkers: Bool
    var autoRefreshInbox: Bool
    var compactReviewSidebar: Bool
    var keepInlinePlayersArmed: Bool
    var notificationAlertsEnabled: Bool
    var preferredExportFormat: ProducerExportFormat

    static let `default` = ProducerSettings(
        defaultPlaybackRate: 1.0,
        highlightCommentMarkers: true,
        autoRefreshInbox: true,
        compactReviewSidebar: false,
        keepInlinePlayersArmed: true,
        notificationAlertsEnabled: true,
        preferredExportFormat: .wav
    )
}

protocol ProducerSettingsReading {
    func load() -> ProducerSettings
}

protocol ProducerSettingsWriting {
    func save(_ settings: ProducerSettings)
}

typealias ProducerSettingsStoring = ProducerSettingsReading & ProducerSettingsWriting

struct UserDefaultsProducerSettingsStore: ProducerSettingsStoring {
    private let defaults: UserDefaults
    private let key = "producer_settings_v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ProducerSettings {
        guard
            let data = defaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(ProducerSettings.self, from: data)
        else {
            return .default
        }

        return settings
    }

    func save(_ settings: ProducerSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
