//
//  EmptyStateView.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import SwiftUI

struct EmptyStateView: View {
    let onAddProject: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                NewProjectCard()
                    .onTapGesture { onAddProject() }
                    .cursor(NSCursor.pointingHand)
                    .padding(.leading, 12)
            }
            
            .frame(width: 120, alignment: .leading)
            
            VStack {
                VStack(spacing: 20) {
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Projects Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    Text("Create your first project to get started")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
}
