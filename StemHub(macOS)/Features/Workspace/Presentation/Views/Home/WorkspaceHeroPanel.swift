//
//  WorkspaceHeroPanel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct WorkspaceHeroPanel: View {
    let projectCountLabel: String
    let bandCountLabel: String
    let onCreateProject: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Workspace")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)

                Text("Browse projects by band, review the latest version metadata, and keep collaboration work tidy.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    statPill(projectCountLabel, systemImage: "music.note.list")
                    statPill(bandCountLabel, systemImage: "person.3.fill")
                }
            }

            Spacer()

            Button(action: onCreateProject) {
                Label("New Project", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(red: 0.80, green: 0.58, blue: 0.99))
        }
        .studioGlassPanel(cornerRadius: 30, padding: 24)
    }
}

private extension WorkspaceHeroPanel {
    func statPill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.12))
            )
    }
}
