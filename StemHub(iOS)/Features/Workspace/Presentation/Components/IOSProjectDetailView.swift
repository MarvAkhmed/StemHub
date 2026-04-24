//
//  IOSProjectDetailView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct IOSProjectDetailView: View {
    let project: IOSProjectSummary
    let bandName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                metadataCard
            }
            .padding(20)
        }
        .iosStudioScreenBackground()
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension IOSProjectDetailView {
    var heroCard: some View {
        IOSStudioCard {
            HStack(alignment: .center, spacing: 16) {
                IOSArtworkThumbnail(
                    artworkBase64: project.posterBase64,
                    fallbackSymbol: "music.note.house",
                    size: 88
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text(bandName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))

                    HStack(spacing: 10) {
                        IOSMetricPill(value: project.branchLabel, label: "Current line")
                        IOSMetricPill(value: project.versionLabel, label: "Current head")
                    }
                }
            }
        }
    }

    var metadataCard: some View {
        IOSStudioCard {
            VStack(alignment: .leading, spacing: 14) {
                IOSSectionHeader("Project Snapshot", subtitle: "A quick mobile summary of the current collaboration state.")

                detailRow(title: "Created", value: project.createdAt.formatted(.dateTime.month().day().year()))
                detailRow(title: "Updated", value: project.updatedAt.formatted(.dateTime.month().day().hour().minute()))
                detailRow(title: "Owner", value: project.createdBy.isEmpty ? "Unknown" : project.createdBy)
                detailRow(title: "Band", value: bandName)
            }
        }
    }

    func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            Text(value)
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
