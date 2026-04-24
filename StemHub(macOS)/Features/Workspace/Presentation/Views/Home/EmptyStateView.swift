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
        VStack(spacing: 24) {
            VStack(spacing: 18) {
                Image(systemName: "music.note.house")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))

                VStack(spacing: 8) {
                    Text("No Projects Yet")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Create your first music workspace to start collaborating with your band.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.70))
                        .multilineTextAlignment(.center)
                }
            }
            .studioGlassPanel(cornerRadius: 28, padding: 28)

            NewProjectCard()
                .onTapGesture { onAddProject() }
                .cursor(NSCursor.pointingHand)
        }
        .frame(maxWidth: 420)
    }
}
