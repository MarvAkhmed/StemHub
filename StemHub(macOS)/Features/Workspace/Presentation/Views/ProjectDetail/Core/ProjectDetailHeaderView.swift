//
//  ProjectDetailHeaderView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct ProjectDetailHeaderView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    @Binding var selectedSection: ProjectDetailSection

    var body: some View {
        HStack(spacing: 18) {
            posterView

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.projectName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Text(viewModel.projectSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 16) {
                    statusPill(
                        title: viewModel.currentBranchName,
                        systemImage: "arrow.triangle.branch"
                    )
                    statusPill(
                        title: viewModel.currentVersionTitle,
                        systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                    )

                    if viewModel.pendingCommitCount > 0 {
                        statusPill(
                            title: "\(viewModel.pendingCommitCount) pending",
                            systemImage: "tray.full"
                        )
                    }

                    if viewModel.selectedVersion != nil {
                        statusPill(
                            title: viewModel.selectedVersionStatusTitle,
                            systemImage: viewModel.canApproveSelectedVersion ? "checkmark.seal" : "checkmark.shield"
                        )
                    }
                }
                .font(.caption)

                ProjectDetailSectionPicker(selection: $selectedSection)
                    .frame(maxWidth: 360)
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
        }
        .studioGlassPanel(cornerRadius: 28, padding: 20)
    }
}

private extension ProjectDetailHeaderView {
    var posterView: some View {
        Group {
            if let image = viewModel.projectPosterImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(StudioPalette.elevated.opacity(0.36))

                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(StudioPalette.elevated.opacity(0.36))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.72))
                    )
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func statusPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.10))
            )
            .foregroundColor(.white.opacity(0.82))
    }
}
