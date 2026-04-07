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
        VStack(spacing: 0) {
            ZStack {
                buildBackgroundRectangle()
                buildAddProjectItem()
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    @ViewBuilder
    private func buildBackgroundRectangle() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .fill(isHovered ? .buttonBackground.opacity(0.7) : Color.gray.opacity(0.5))
            .frame(height: 100)
        
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
            )
    }
    
    @ViewBuilder
    private func buildAddProjectItem() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.sanchezItalic14)
            
            Text("New Project")
                .font(.sanchezItalic18)
            
            Text("Create a new music project")
                .font(.caption)
                .font(.sanchezItalic14)
        }
    }
}
