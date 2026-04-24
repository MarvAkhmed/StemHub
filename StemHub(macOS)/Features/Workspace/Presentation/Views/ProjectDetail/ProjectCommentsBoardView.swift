//
//  ProjectCommentsBoardView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProjectCommentsBoardView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryPanel
                composerPanel
                reviewQueuePanel
            }
            .padding(.vertical, 2)
        }
    }
}

private extension ProjectCommentsBoardView {
    var summaryPanel: some View {
        ProjectDetailPanel(title: "Comment Overview", systemImage: "checklist") {
            HStack(spacing: 12) {
                countBadge(title: "Open", count: openCommentsCount, tint: .purple)
                countBadge(title: "Accepted", count: acceptedCommentsCount, tint: .green)
                countBadge(title: "Rejected", count: rejectedCommentsCount, tint: .orange)
                Spacer()
            }
        }
    }

    var composerPanel: some View {
        ProjectDetailPanel(title: "Add Review Note", systemImage: "square.and.pencil") {
            ProjectCommentComposerView(viewModel: viewModel)
        }
    }

    var reviewQueuePanel: some View {
        ProjectDetailPanel(title: "Version Review Queue", systemImage: "text.bubble.fill") {
            if viewModel.versionComments.isEmpty {
                ContentUnavailableView(
                    "No Comments Yet",
                    systemImage: "bubble.left.and.exclamationmark.bubble.right",
                    description: Text("Notes for the current version will appear here as soon as collaborators leave feedback.")
                )
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.versionComments) { comment in
                        ProjectCommentCardView(viewModel: viewModel, comment: comment)
                    }
                }
            }
        }
    }

    var openCommentsCount: Int {
        viewModel.versionComments.filter { $0.reviewState == .open }.count
    }

    var acceptedCommentsCount: Int {
        viewModel.versionComments.filter { $0.reviewState == .accepted }.count
    }

    var rejectedCommentsCount: Int {
        viewModel.versionComments.filter { $0.reviewState == .rejected }.count
    }

    func countBadge(title: String, count: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.title2.weight(.bold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }
}

