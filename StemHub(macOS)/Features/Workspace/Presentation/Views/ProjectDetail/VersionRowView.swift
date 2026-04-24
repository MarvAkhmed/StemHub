//
//  VersionRowView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI


struct VersionRowView: View {
    let version: ProjectVersion
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Version \(version.versionNumber)")
                    .font(.body.weight(isSelected ? .semibold : .regular))
                Text(
                    version.createdAt.formatted(
                        .dateTime.month(.abbreviated).day().hour().minute()
                    )
                )
                .font(.caption)
                .foregroundColor(.secondary)

                if let notes = version.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(version.approvalState.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(version.approvalState == .approved ? .green : .orange)
            }

            Spacer()

            Text("\(version.fileVersionIDs.count)")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.accentColor.opacity(isSelected ? 0.18 : 0.10)))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
