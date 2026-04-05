//
//  ProjectCardView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation
import SwiftUI

struct ProjectCardView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let posterURL = project.posterURL {
                let poster = URL(string: posterURL)
                AsyncImage(url: poster) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
            } else {
                Color.gray.opacity(0.2)
                    .frame(height: 120)
                    .overlay(Text("No Poster").foregroundColor(.gray))
                    .cornerRadius(8)
            }
            
            Text(project.name)
                .font(.headline)
            
            Text("Project ID: \(project.id)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let currentVersionID = project.currentVersionID
            Text("Version: \(currentVersionID.prefix(8))…")
                .font(.caption2)
                .foregroundColor(.secondary)
            
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.windowBackgroundColor)))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
