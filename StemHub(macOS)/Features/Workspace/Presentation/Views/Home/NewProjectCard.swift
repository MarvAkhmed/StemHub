//
//  NewProjectCard.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI


struct NewProjectCard: View {
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            buildBackgroundRectangle()
            buildAddProjectItem()
        }
        .frame(minHeight: 220)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.24, dampingFraction: 0.86), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private func buildBackgroundRectangle() -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .fill(isHovered ? StudioPalette.border.opacity(0.95) : StudioPalette.border.opacity(0.70))
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(StudioPalette.elevated.opacity(0.24))
                    )
            )
    }
    
    @ViewBuilder
    private func buildAddProjectItem() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
            
            Text("New Project")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("Create a new music project")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}
