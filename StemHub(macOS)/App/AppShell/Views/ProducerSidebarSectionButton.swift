//
//  ProducerSidebarSectionButton.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 24.04.2026.
//

import SwiftUI

struct ProducerSidebarSectionButton: View {
    let section: MainAppSection
    @Binding var selectedSection: MainAppSection
    let showsBadge: Bool
    let badgeText: String

    var body: some View {
        Button {
            selectedSection = section
        } label: {
            HStack(spacing: ProducerSidebarLayoutTokens.rowSpacing) {
                Image(systemName: section.systemImage)
                    .frame(
                        width: ProducerSidebarLayoutTokens.iconSize,
                        height: ProducerSidebarLayoutTokens.iconSize
                    )
                    .foregroundStyle(
                        isSelected
                        ? Color.white
                        : Color.white.opacity(ProducerSidebarColorTokens.unselectedIconOpacity)
                    )

                VStack(alignment: .leading, spacing: ProducerSidebarLayoutTokens.titleSubtitleSpacing) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(section.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(ProducerSidebarColorTokens.rowSubtitleOpacity))
                        .lineLimit(1)
                }

                Spacer()

                if showsBadge {
                    Text(badgeText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ProducerSidebarColorTokens.badgeTextColor)
                        .padding(.horizontal, ProducerSidebarLayoutTokens.badgeHorizontalPadding)
                        .padding(.vertical, ProducerSidebarLayoutTokens.badgeVerticalPadding)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    Capsule()
                                        .fill(ProducerSidebarColorTokens.badgeBackgroundColor.opacity(0.16))
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(StudioPalette.glassHighlight.opacity(0.8), lineWidth: 0.6)
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(StudioPalette.border.opacity(0.55), lineWidth: 0.8)
                                }
                        )
                }
            }
            .padding(.horizontal, ProducerSidebarLayoutTokens.rowHorizontalPadding)
            .padding(.vertical, ProducerSidebarLayoutTokens.rowVerticalPadding)
            .background(background)
        }
        .buttonStyle(.plain)
    }
}

private extension ProducerSidebarSectionButton {
    var isSelected: Bool {
        selectedSection == section
    }

    var background: some View {
        RoundedRectangle(cornerRadius: ProducerSidebarLayoutTokens.rowCornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: ProducerSidebarLayoutTokens.rowCornerRadius, style: .continuous)
                    .fill(
                        isSelected
                        ? ProducerSidebarColorTokens.selectedRowFillColor.opacity(ProducerSidebarColorTokens.selectedRowOpacity)
                        : ProducerSidebarColorTokens.unselectedRowFillColor.opacity(ProducerSidebarColorTokens.unselectedRowOpacity)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: ProducerSidebarLayoutTokens.rowCornerRadius, style: .continuous)
                    .stroke(StudioPalette.glassHighlight.opacity(0.75), lineWidth: 0.7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ProducerSidebarLayoutTokens.rowCornerRadius, style: .continuous)
                    .stroke(StudioPalette.border.opacity(0.62), lineWidth: 0.9)
            }
    }
}
