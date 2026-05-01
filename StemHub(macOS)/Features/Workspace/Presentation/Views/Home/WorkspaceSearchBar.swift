//
//  WorkspaceSearchBar.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 24.04.2026.
//

import SwiftUI

struct WorkspaceSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.82))

            TextField("Search projects by name", text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.62))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(background)
    }
}

private extension WorkspaceSearchBar {
    var background: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(StudioPalette.tintSoft.opacity(0.08))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(StudioPalette.glassHighlight.opacity(0.85), lineWidth: 0.7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(StudioPalette.border.opacity(0.62), lineWidth: 1)
            }
    }
}
