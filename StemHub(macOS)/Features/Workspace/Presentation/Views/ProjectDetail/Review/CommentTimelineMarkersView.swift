//
//  CommentTimelineMarkersView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct CommentTimelineMarkersView: View {
    let comments: [Comment]
    let duration: Double
    let onSelect: (Comment) -> Void

    @State private var hoveredCommentID: String?

    var body: some View {
        let visibleComments = comments.filter {
            $0.timestamp != nil && $0.isHiddenFromTimeline == false
        }

        if visibleComments.isEmpty || duration <= 0 {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                            .offset(y: 8)

                        ForEach(visibleComments) { comment in
                            marker(for: comment, width: geometry.size.width)
                        }

                        if let hoveredComment = visibleComments.first(where: { $0.id == hoveredCommentID }) {
                            hoverBubble(for: hoveredComment, width: geometry.size.width)
                        }
                    }
                }
                .frame(height: 38)

                Text("Hover a marker to preview the note, or click it to jump to that timestamp.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private extension CommentTimelineMarkersView {
    func marker(for comment: Comment, width: CGFloat) -> some View {
        let xPosition = markerPosition(for: comment.timestamp ?? 0, width: width)

        return Button {
            onSelect(comment)
        } label: {
            Circle()
                .fill(markerColor(for: comment.reviewState))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .position(x: xPosition, y: 11)
        .onHover { isHovering in
            hoveredCommentID = isHovering ? comment.id : nil
        }
        .help(comment.text)
    }

    func hoverBubble(for comment: Comment, width: CGFloat) -> some View {
        Text(comment.text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .frame(maxWidth: 220, alignment: .leading)
            .position(x: markerPosition(for: comment.timestamp ?? 0, width: width), y: 30)
    }

    func markerPosition(for timestamp: Double, width: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        let normalized = max(0, min(timestamp / duration, 1))
        return max(8, min(width - 8, width * normalized))
    }

    func markerColor(for state: CommentReviewState) -> Color {
        switch state {
        case .open:
            return Color(red: 0.83, green: 0.61, blue: 0.97)
        case .accepted:
            return .green
        case .rejected:
            return .orange
        }
    }
}
