//
//  ProjectCard.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import SwiftUI

struct ProjectCard: View {
    let viewModel: ProjectCardViewModel
    let onOpen: () -> Void
    let onDelete: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    posterSection
                    infoSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.24 : 0.12),
                    radius: isHovered ? 24 : 16,
                    y: isHovered ? 16 : 10
                )
                .scaleEffect(isHovered ? 1.01 : 1.0)
            }
            .buttonStyle(.plain)

            if let onDelete, viewModel.canDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(isHovered ? 0.44 : 0.28))
                        )
                }
                .buttonStyle(.plain)
                .padding(12)
                .opacity(isHovered ? 1 : 0.82)
            }
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.86), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .cursor(NSCursor.pointingHand)
    }
}

private extension ProjectCard {
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(StudioPalette.elevated.opacity(0.22))
            )
    }

    var posterSection: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let image = viewModel.projectPosterImage {
                    ZStack {
                        Rectangle()
                            .fill(StudioPalette.elevated.opacity(0.28))

                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .aspectRatio(contentMode: .fit)
                            .padding(10)
                    }
                } else {
                    noPosterPlaceholder
                }
            }
            .frame(height: 170)
            .clipped()

            HStack {
                badge(title: viewModel.versionBadgeTitle, tint: Color.black.opacity(0.42))
                Spacer()
                badge(title: viewModel.collaboratorBadgeTitle, tint: Color.white.opacity(0.16))
            }
            .padding(14)
        }
    }

    var noPosterPlaceholder: some View {
        Rectangle()
            .fill(StudioPalette.elevated.opacity(0.32))
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    Text(viewModel.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(18)
            )
    }

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.name)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Label(viewModel.updatedAtFormatted, systemImage: "calendar")
                    Label(viewModel.versionTitle, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.70))
            }

            HStack {
                Text(viewModel.approvalTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.approvalColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.approvalColor.opacity(0.14))
                    )
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Latest Version Metadata")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.84))

                if viewModel.changeMetrics.isEmpty {
                    Text(viewModel.metadataDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(viewModel.changeMetrics) { metric in
                            changeMetricCard(metric)
                        }
                    }
                }
            }

            if isHovered {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Open project")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.90))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(18)
    }

    func badge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tint)
            )
    }

    func changeMetricCard(_ metric: ProjectCardViewModel.ChangeMetric) -> some View {
        HStack(spacing: 8) {
            Image(systemName: metric.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(metric.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.62))
                Text("\(metric.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}
