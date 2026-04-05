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
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .fill(isHovered ? Color.accentColor : Color.gray.opacity(0.5))
                    .frame(height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 48))
                        .foregroundColor(isHovered ? .accentColor : .gray)
                    
                    Text("New Project")
                        .font(.headline)
                        .foregroundColor(isHovered ? .accentColor : .primary)
                    
                    Text("Create a new music project")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Start a new project")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
