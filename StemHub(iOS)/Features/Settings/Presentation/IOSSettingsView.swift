//
//  IOSSettingsView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct IOSSettingsView: View {
    @ObservedObject var viewModel: IOSSettingsViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                playbackSection
                collaborationSection
                exportSection
                accountSection
            }
            .padding(20)
        }
        .iosStudioScreenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out of StemHub?", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You’ll need to sign in again to reopen your projects and collaborations.")
        }
    }
}

private extension IOSSettingsView {
    var header: some View {
        IOSStudioCard {
            IOSSectionHeader(
                "Studio preferences",
                subtitle: "Fine-tune playback, review, notifications, and export defaults for mobile sessions."
            )
        }
    }

    var playbackSection: some View {
        settingsCard(title: "Playback & Review", symbol: "waveform") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Default playback rate")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%.2fx", viewModel.defaultPlaybackRate))
                        .foregroundStyle(.white.opacity(0.72))
                }

                Slider(value: $viewModel.defaultPlaybackRate, in: 0.5...1.5, step: 0.05)
                    .tint(Color(red: 0.79, green: 0.58, blue: 0.99))

                Toggle("Show timestamp markers", isOn: $viewModel.highlightCommentMarkers)
                    .tint(Color(red: 0.79, green: 0.58, blue: 0.99))

                Toggle("Keep inline players ready", isOn: $viewModel.keepInlinePlayersArmed)
                    .tint(Color(red: 0.79, green: 0.58, blue: 0.99))

                Toggle("Use compact review layout", isOn: $viewModel.compactReviewSidebar)
                    .tint(Color(red: 0.79, green: 0.58, blue: 0.99))
            }
            .foregroundStyle(.white)
        }
    }

    var collaborationSection: some View {
        settingsCard(title: "Collaboration", symbol: "person.3.fill") {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Refresh inbox automatically", isOn: $viewModel.autoRefreshInbox)
                    .tint(Color(red: 0.79, green: 0.58, blue: 0.99))

                Toggle("Allow collaboration alerts", isOn: $viewModel.notificationAlertsEnabled)
                    .tint(Color(red: 0.79, green: 0.58, blue: 0.99))
            }
            .foregroundStyle(.white)
        }
    }

    var exportSection: some View {
        settingsCard(title: "Export", symbol: "square.and.arrow.up.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferred mix export format")
                    .foregroundStyle(.white)

                Picker("Preferred export format", selection: $viewModel.preferredExportFormat) {
                    ForEach(IOSProducerExportFormat.allCases, id: \.self) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    var accountSection: some View {
        settingsCard(title: "Account", symbol: "person.crop.circle.badge.checkmark") {
            Button("Sign Out") {
                showSignOutConfirmation = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.83, green: 0.44, blue: 0.63))
        }
    }

    func settingsCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        IOSStudioCard {
            VStack(alignment: .leading, spacing: 16) {
                Label(title, systemImage: symbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                content()
            }
        }
    }
}
