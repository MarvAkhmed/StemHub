//
//  ProjectCard.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import SwiftUI

struct ProjectCard: View {
    @ObservedObject var viewModel: ProjectCardViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            posterSection
            infoSection
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.15 : 0.08),
                    radius: isHovered ? 12 : 8,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .cornerRadius(12)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .cursor(NSCursor.pointingHand)
    }
    
    // MARK: - Poster Section
    private var posterSection: some View {
        ZStack {
            if let image = viewModel.projectPosterImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                noPosterPlaceholder
            }
        }
        .frame(height: 160)
        .clipped()
        .overlay(versionBadge, alignment: .topTrailing)
    }
    
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay(ProgressView().scaleEffect(0.8))
    }
    
    private var failurePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("Failed to load")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            )
    }
    
    private var noPosterPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(viewModel.name)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .multilineTextAlignment(.center)
                }
            )
    }
    
    private var versionBadge: some View {
        Text(viewModel.versionPrefix)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.7)))
            .foregroundColor(.white)
            .padding(8)
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(viewModel.updatedAtFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(viewModel.bandIDPrefix)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if isHovered {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                    Text("Click to open")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
