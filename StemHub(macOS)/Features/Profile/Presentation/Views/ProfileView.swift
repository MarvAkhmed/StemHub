//
//  ProfileView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import AppKit
import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            StudioBackdropView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    bandsSection
                    releaseSection
                }
                .padding(28)
            }
        }
        .studioSafeArea()
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert("Profile", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearError()
                }
            }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private extension ProfileView {
    var profileHeader: some View {
        contentCard {
            HStack(alignment: .center, spacing: 18) {
                avatar

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.currentUser?.name ?? "Producer")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text(viewModel.currentUser?.email ?? "Signed in")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.76))

                    HStack(spacing: 10) {
                        statPill(viewModel.bandCountLabel)
                        statPill(viewModel.releaseCountLabel)
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
        }
    }

    var bandsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bands")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            if viewModel.bands.isEmpty {
                contentCard {
                    Text("Your band memberships will appear here once you create or accept an invite.")
                        .foregroundStyle(.white.opacity(0.72))
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.bands, id: \.id) { band in
                        contentCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(band.name)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if band.adminUserID == viewModel.currentUser?.id {
                                        statPill("Admin")
                                    }
                                }

                                Text("\(band.memberIDs.count) collaborator\(band.memberIDs.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.70))

                                Text("\(band.projectIDs.count) linked project\(band.projectIDs.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.58))
                            }
                        }
                    }
                }
            }
        }
    }

    var releaseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ready To Publish")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            if viewModel.releaseCandidates.isEmpty {
                contentCard {
                    Text("As soon as projects have saved versions, they’ll surface here for publishing workflows and plugin handoff.")
                        .foregroundStyle(.white.opacity(0.72))
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.releaseCandidates) { candidate in
                        contentCard {
                            HStack(spacing: 14) {
                                artwork(for: candidate)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(candidate.projectName)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(candidate.bandName)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.72))
                                    Text(candidate.latestVersionLabel)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.56))
                                }

                                Spacer()

                                if candidate.isBandAdmin {
                                    statPill("Can Publish")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var avatar: some View {
        ZStack {
            Circle()
                .fill(StudioPalette.elevated.opacity(0.54))
                .overlay(
                    Circle()
                        .stroke(StudioPalette.border.opacity(0.72), lineWidth: 1)
                )

            Text(initials(for: viewModel.currentUser?.name ?? viewModel.currentUser?.email ?? "S"))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 78, height: 78)
    }

    func statPill(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.white.opacity(0.12))
            )
    }

    func artwork(for candidate: ReleaseCandidate) -> some View {
        Group {
            if
                let base64 = candidate.artworkBase64,
                let data = Data(base64Encoded: base64),
                let image = NSImage(data: data)
            {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(StudioPalette.elevated.opacity(0.42))
                    Image(systemName: "waveform")
                        .foregroundStyle(.white.opacity(0.88))
                }
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func contentCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .studioGlassPanel(cornerRadius: 24, padding: 18)
    }

    func initials(for value: String) -> String {
        let tokens = value
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let initials = String(tokens)
        return initials.isEmpty ? "S" : initials.uppercased()
    }
}
