//
//  WorkspaceView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 01.04.2026.
//

import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var viewModel: WorkspaceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard

                if let featuredProject = viewModel.featuredProject {
                    featuredProjectCard(featuredProject)
                }

                bandsSection
                projectsSection
            }
            .padding(20)
        }
        .iosStudioScreenBackground()
        .navigationTitle("Workspace")
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
        .alert("Workspace", isPresented: Binding(
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
        .navigationDestination(for: IOSProjectSummary.self) { project in
            IOSProjectDetailView(
                project: project,
                bandName: viewModel.bandName(for: project)
            )
        }
    }
}

private extension WorkspaceView {
    var heroCard: some View {
        IOSStudioCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(viewModel.greeting), \(viewModel.displayName)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Pick up where your session left off, review band activity, and jump into the latest project state.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 10) {
                    IOSMetricPill(value: viewModel.bandCountLabel, label: "Bands")
                    IOSMetricPill(value: viewModel.projectCountLabel, label: "Projects")
                }
            }
        }
    }

    func featuredProjectCard(_ project: IOSProjectSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            IOSSectionHeader("Continue reviewing", subtitle: "The most recently updated project in your workspace.")

            NavigationLink(value: project) {
                IOSStudioCard {
                    HStack(spacing: 16) {
                        IOSArtworkThumbnail(
                            artworkBase64: project.posterBase64,
                            fallbackSymbol: "music.note.house",
                            size: 86
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text(project.name)
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text(viewModel.bandName(for: project))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.72))

                            Text(project.updatedAt.formatted(.dateTime.month().day().hour().minute()))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.56))

                            HStack(spacing: 8) {
                                IOSMetricPill(value: project.branchLabel, label: "Line")
                                IOSMetricPill(value: project.versionLabel, label: "Head")
                            }
                        }

                        Spacer()
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    var bandsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            IOSSectionHeader("Bands", subtitle: "Your collaboration spaces.")

            if viewModel.bands.isEmpty {
                IOSStudioCard {
                    ContentUnavailableView(
                        "No Bands Yet",
                        systemImage: "person.3.sequence.fill",
                        description: Text("Create a project on desktop or accept an invite to start filling this space.")
                    )
                    .foregroundStyle(.white.opacity(0.90))
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.bands) { band in
                            IOSStudioCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(band.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text(band.memberCountLabel)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.72))

                                    Text(band.projectCountLabel)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.56))
                                }
                                .frame(width: 180, alignment: .leading)
                            }
                            .frame(width: 180)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    var projectsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            IOSSectionHeader("Projects", subtitle: "All projects connected to the bands you’re part of.")

            if viewModel.projects.isEmpty {
                IOSStudioCard {
                    ContentUnavailableView(
                        "No Projects Yet",
                        systemImage: "waveform.path.badge.minus",
                        description: Text("Projects linked to your bands will appear here once they’re created.")
                    )
                    .foregroundStyle(.white.opacity(0.90))
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.projects) { project in
                        NavigationLink(value: project) {
                            IOSStudioCard {
                                HStack(spacing: 14) {
                                    IOSArtworkThumbnail(
                                        artworkBase64: project.posterBase64,
                                        fallbackSymbol: "music.note",
                                        size: 70
                                    )

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(project.name)
                                            .font(.headline)
                                            .foregroundStyle(.white)

                                        Text(viewModel.bandName(for: project))
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.72))

                                        Text(project.updatedAt.formatted(.dateTime.month().day().hour().minute()))
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.56))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.white.opacity(0.48))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

