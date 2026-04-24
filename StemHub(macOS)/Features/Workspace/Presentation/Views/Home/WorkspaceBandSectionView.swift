//
//  WorkspaceBandSectionView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct WorkspaceBandSectionView: View {
    let section: WorkspaceBandSection
    let columns: [GridItem]
    let onOpenProject: (Project) -> Void
    let onDeleteProject: (WorkspaceProjectItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(section.projects) { item in
                    ProjectCard(
                        viewModel: ProjectCardViewModel(item: item),
                        onOpen: { onOpenProject(item.project) },
                        onDelete: item.canDelete ? { onDeleteProject(item) } : nil
                    )
                }
            }
        }
        .studioGlassPanel(cornerRadius: 28, padding: 22)
    }
}

private extension WorkspaceBandSectionView {
    var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(section.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text(section.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            Text("Band")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.80))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                )
        }
    }
}

