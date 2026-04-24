//
//  ProjectChangesBoardView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProjectChangesBoardView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                contextPanel
                changesPanel
            }
            .padding(.vertical, 2)
        }
    }
}

private extension ProjectChangesBoardView {
    var contextPanel: some View {
        ProjectDetailPanel(title: "Review Context", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.workspaceTitle)
                    .font(.title3.weight(.semibold))

                Text(viewModel.workspaceSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    statusBadge(title: viewModel.currentBranchName, systemImage: "arrow.triangle.branch")
                    statusBadge(title: viewModel.currentVersionTitle, systemImage: "clock")
                    statusBadge(title: viewModel.selectedVersionStatusTitle, systemImage: "checkmark.seal")
                }
            }
        }
    }

    var changesPanel: some View {
        ProjectDetailPanel(title: "Diff Preview", systemImage: "square.split.2x1") {
            if let diff = viewModel.versionDiff {
                DiffPreviewView(diff: diff)
                    .frame(minHeight: 280)
            } else {
                ContentUnavailableView(
                    "No Version Diff Selected",
                    systemImage: "doc.badge.clock",
                    description: Text("Pick a saved version from the history sidebar to inspect what changed.")
                )
                .frame(maxWidth: .infinity, minHeight: 240)
            }
        }
    }

    func statusBadge(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.10))
            )
    }
}

