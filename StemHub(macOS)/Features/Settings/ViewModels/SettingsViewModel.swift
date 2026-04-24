//
//  SettingsViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var defaultPlaybackRate: Double
    @Published var highlightCommentMarkers: Bool
    @Published var autoRefreshInbox: Bool
    @Published var compactReviewSidebar: Bool
    @Published var keepInlinePlayersArmed: Bool
    @Published var notificationAlertsEnabled: Bool
    @Published var preferredExportFormat: ProducerExportFormat

    private let sessionController: any SessionLoggingOut
    private let store: any ProducerSettingsStoring
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: any SessionLoggingOut,
        store: any ProducerSettingsStoring
    ) {
        self.sessionController = authService
        self.store = store

        let settings = self.store.load()
        defaultPlaybackRate = settings.defaultPlaybackRate
        highlightCommentMarkers = settings.highlightCommentMarkers
        autoRefreshInbox = settings.autoRefreshInbox
        compactReviewSidebar = settings.compactReviewSidebar
        keepInlinePlayersArmed = settings.keepInlinePlayersArmed
        notificationAlertsEnabled = settings.notificationAlertsEnabled
        preferredExportFormat = settings.preferredExportFormat

        bindPersistence()
    }

    func persist() {
        store.save(
            ProducerSettings(
                defaultPlaybackRate: defaultPlaybackRate,
                highlightCommentMarkers: highlightCommentMarkers,
                autoRefreshInbox: autoRefreshInbox,
                compactReviewSidebar: compactReviewSidebar,
                keepInlinePlayersArmed: keepInlinePlayersArmed,
                notificationAlertsEnabled: notificationAlertsEnabled,
                preferredExportFormat: preferredExportFormat
            )
        )
    }

    func signOut() {
        sessionController.logout()
    }

    private func bindPersistence() {
        Publishers.CombineLatest4(
            $defaultPlaybackRate.removeDuplicates(),
            $highlightCommentMarkers.removeDuplicates(),
            $autoRefreshInbox.removeDuplicates(),
            $compactReviewSidebar.removeDuplicates()
        )
        .combineLatest(
            Publishers.CombineLatest3(
                $keepInlinePlayersArmed.removeDuplicates(),
                $notificationAlertsEnabled.removeDuplicates(),
                $preferredExportFormat.removeDuplicates()
            )
        )
        .dropFirst()
        .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _ in
            self?.persist()
        }
        .store(in: &cancellables)
    }
}
