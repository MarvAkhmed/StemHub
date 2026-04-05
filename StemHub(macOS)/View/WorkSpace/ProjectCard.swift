//
//  ProjectCard.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import SwiftUI

// MARK: - Project Card Component
struct ProjectCard: View {
    let project: Project
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster Image Section
            ZStack {
                if let posterURL = project.posterURL, let url = URL(string: posterURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // Loading state
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        case .success(let image):
                            // Success state
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            // Failure state
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
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    // No poster - show placeholder
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
                                Text(project.name)
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .multilineTextAlignment(.center)
                            }
                        )
                }
            }
            .frame(height: 160)
            .clipped()
            .overlay(
                // Version badge
                VStack {
                    HStack {
                        Spacer()
                        Text("v\(project.currentVersionID.prefix(6))")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                                    .blur(radius: 0.5)
                            )
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    Spacer()
                }
            )
            
            // Project Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(project.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(project.updatedAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(project.bandID.prefix(8))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Progress indicator for sync status (optional)
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
}

// MARK: - Project Card with Action Button
struct ProjectCardWithAction: View {
    let project: Project
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            ProjectCard(project: project)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Compact Project Card (for Sidebar)
struct CompactProjectCard: View {
    let project: Project
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini poster
            Group {
                if let posterURL = project.posterURL, let url = URL(string: posterURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                            .overlay(ProgressView().scaleEffect(0.5))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 36, height: 36)
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                    .fontWeight(isHovered ? .semibold : .regular)
                    .lineLimit(1)
                
                Text("Updated \(project.updatedAt, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isHovered {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}


// MARK: - Loading Project Card
struct LoadingProjectCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 160)
                .overlay(
                    ProgressView()
                        .scaleEffect(0.8)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(width: 120)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
                    .frame(width: 80)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
                    .frame(width: 100)
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 4)
        )
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    let sampleProject = Project(
        id: "123",
        name: "Awesome Music Project",
        posterURL: nil,
        bandID: "band_456",
        createdBy: "user_789",
        currentBranchID: "main",
        currentVersionID: "abc123def456",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    return VStack(spacing: 20) {
        Text("Regular Project Card")
            .font(.headline)
        ProjectCard(project: sampleProject)
            .frame(width: 220)
        
        Text("Compact Project Card")
            .font(.headline)
            .padding(.top)
        CompactProjectCard(project: sampleProject)
            .frame(width: 300)
        
        Text("Loading Card")
            .font(.headline)
            .padding(.top)
        LoadingProjectCard()
            .frame(width: 220)
    }
    .padding()
    .frame(width: 500, height: 700)
}
