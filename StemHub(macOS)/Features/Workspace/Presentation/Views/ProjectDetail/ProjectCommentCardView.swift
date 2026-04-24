//
//  ProjectCommentCardView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProjectCommentCardView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text((comment.filePath as NSString).lastPathComponent)
                        .font(.headline)

                    Text(timestampLabel(for: comment.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(comment.reviewState.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(statusColor(for: comment.reviewState).opacity(0.16)))
            }

            Text(comment.text)
                .font(.body)

            HStack(spacing: 10) {
                Label(viewModel.authorName(for: comment.userID), systemImage: "person.crop.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(comment.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("Focus") {
                    Task { await viewModel.focus(on: comment) }
                }
                .buttonStyle(.bordered)

                Button("Accept") {
                    Task { await viewModel.setCommentReviewState(.accepted, for: comment) }
                }
                .buttonStyle(.borderedProminent)

                Button("Reject") {
                    Task { await viewModel.setCommentReviewState(.rejected, for: comment) }
                }
                .buttonStyle(.bordered)

                if comment.reviewState != .open {
                    Button("Reopen") {
                        Task { await viewModel.setCommentReviewState(.open, for: comment) }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private extension ProjectCommentCardView {
    func timestampLabel(for timestamp: Double?) -> String {
        guard let timestamp else { return "General note" }

        let totalSeconds = max(Int(timestamp.rounded(.down)), 0)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    func statusColor(for state: CommentReviewState) -> Color {
        switch state {
        case .open:
            return Color.purple
        case .accepted:
            return Color.green
        case .rejected:
            return Color.orange
        }
    }
}

