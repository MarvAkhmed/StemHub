//
//  ProjectDetailPanel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProjectDetailPanel<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioGlassPanel()
    }
}

