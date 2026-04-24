//
//  IOSProfileView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct IOSProfileView: View {
    @ObservedObject var viewModel: IOSProfileViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                bandsSection
                releasesSection
            }
            .padding(20)
        }
        .iosStudioScreenBackground()
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .tint(.white)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
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

private extension IOSProfileView {
    var headerCard: some View {
        IOSStudioCard {
            HStack(alignment: .center, spacing: 16) {
                IOSUserAvatar(source: viewModel.currentUser?.name ?? viewModel.currentUser?.email ?? "StemHub")

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.currentUser?.name ?? "Producer")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text(viewModel.currentUser?.email ?? "Signed in")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))

                    HStack(spacing: 10) {
                        IOSMetricPill(value: viewModel.bandCountLabel, label: "Bands")
                        IOSMetricPill(value: viewModel.releaseCountLabel, label: "Releases")
                    }
                }
            }
        }
    }

    var bandsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            IOSSectionHeader("Bands", subtitle: "Your active collaboration circles.")

            if viewModel.bands.isEmpty {
                IOSStudioCard {
                    Text("Your band memberships will show up here after you create a band or accept an invitation.")
                        .foregroundStyle(.white.opacity(0.72))
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.bands) { band in
                        IOSStudioCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(band.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(band.memberCountLabel)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.72))
                                    Text(band.projectCountLabel)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.58))
                                }

                                Spacer()

                                if band.adminUserID == viewModel.currentUser?.id {
                                    Text("Admin")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.white.opacity(0.12)))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var releasesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            IOSSectionHeader("Ready to publish", subtitle: "Approved versions that can move into release or plugin workflows.")

            if viewModel.releaseCandidates.isEmpty {
                IOSStudioCard {
                    Text("Once approved versions exist, they’ll appear here with the band they belong to.")
                        .foregroundStyle(.white.opacity(0.72))
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.releaseCandidates) { candidate in
                        IOSStudioCard {
                            HStack(spacing: 14) {
                                IOSArtworkThumbnail(
                                    artworkBase64: candidate.artworkBase64,
                                    fallbackSymbol: "waveform",
                                    size: 68
                                )

                                VStack(alignment: .leading, spacing: 6) {
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
                                    Text("Can Publish")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.white.opacity(0.12)))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
