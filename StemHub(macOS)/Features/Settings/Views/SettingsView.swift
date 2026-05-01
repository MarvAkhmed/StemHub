//
//  SettingsView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        ZStack {
            StudioBackdropView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    audioSection
                    collaborationSection
                    exportSection
                    accountSection
                }
                .padding(28)
            }
        }
        .studioSafeArea()
        .alert("Sign Out of StemHub?", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You will need to sign in again to access your workspace and band projects.")
        }
    }
}

private extension SettingsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Studio Settings")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)

            Text("Tune playback, review, notifications, and export behavior for longer sessions.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.76))
        }
    }

    var audioSection: some View {
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
                    .tint(StudioPalette.tint)

                Toggle("Show timestamp markers during review", isOn: $viewModel.highlightCommentMarkers)
                    .foregroundStyle(.white)

                Toggle("Keep inline stem players prepared", isOn: $viewModel.keepInlinePlayersArmed)
                    .foregroundStyle(.white)

                Toggle("Use compact review sidebar", isOn: $viewModel.compactReviewSidebar)
                    .foregroundStyle(.white)
            }
            .studioToggleSwitch()
        }
    }

    var collaborationSection: some View {
        settingsCard(title: "Collaboration", symbol: "person.3.fill") {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Refresh invitation inbox when the shell opens", isOn: $viewModel.autoRefreshInbox)
                    .foregroundStyle(.white)

                Toggle("Allow collaboration alerts", isOn: $viewModel.notificationAlertsEnabled)
                    .foregroundStyle(.white)
            }
            .studioToggleSwitch()
        }
    }

    var exportSection: some View {
        settingsCard(title: "Export", symbol: "square.and.arrow.up.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferred mix export format")
                    .foregroundStyle(.white)

                Picker("Preferred export format", selection: $viewModel.preferredExportFormat) {
                    ForEach(ProducerExportFormat.allCases, id: \.self) { format in
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
            .tint(Color(red: 0.80, green: 0.42, blue: 0.62))
        }
    }

    func settingsCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioGlassPanel(cornerRadius: 24, padding: 20)
    }
}
