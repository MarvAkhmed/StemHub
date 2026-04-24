//
//  ProducerSidebarView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProducerSidebarView: View {
    @Binding var selectedSection: MainAppSection
    let pendingInvitationCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            VStack(alignment: .leading, spacing: 8) {
                ForEach(MainAppSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        sidebarRow(for: section)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            ZStack {
                Rectangle()
                    .fill(.regularMaterial)
                Rectangle()
                    .fill(StudioPalette.elevated.opacity(0.24))
            }
        )
    }
}

private extension ProducerSidebarView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("StemHub Studio")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("A calmer place to shape versions, feedback, and release work.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    func sidebarRow(for section: MainAppSection) -> some View {
        let isSelected = selectedSection == section

        return HStack(spacing: 12) {
            Image(systemName: section.systemImage)
                .frame(width: 18, height: 18)
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(section.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }

            Spacer()

            if section == .inbox, pendingInvitationCount > 0 {
                Text("\(pendingInvitationCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.30, green: 0.12, blue: 0.50))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected
                    ? Color.white.opacity(0.18)
                    : Color.white.opacity(0.06)
                )
        )
    }
}
