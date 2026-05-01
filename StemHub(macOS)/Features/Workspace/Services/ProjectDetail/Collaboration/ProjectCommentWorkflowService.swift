//
//  ProjectCommentWorkflowService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectCommentsSnapshot {
    let versionID: String?
    let versionComments: [Comment]
    let selectedFileComments: [Comment]
}

struct ProjectCommentDraftInput {
    let projectID: String
    let branchID: String
    let versionID: String
    let filePath: String
    let text: String
    let timestamp: Double?
    let userID: String
}

protocol ProjectCommentWorkflowing {
    func loadComments(
        versionID: String?,
        selectedFilePath: String?
    ) async throws -> ProjectCommentsSnapshot

    func selectedFileComments(
        from versionComments: [Comment],
        selectedFilePath: String?
    ) -> [Comment]

    func visibleTimelineComments(from comments: [Comment]) -> [Comment]
    func commentsNear(timestampSeconds: Double, comments: [Comment], tolerance: Double) -> [Comment]
    func commentMarkers(from comments: [Comment], fileID: String, duration: Double) -> [CommentMarker]
    func addComment(_ input: ProjectCommentDraftInput) async throws
    func updateCommentReview(commentID: String, state: CommentReviewState) async throws
}

final class ProjectCommentWorkflowService: ProjectCommentWorkflowing {
    private let commentService: ProjectCommentServiceProtocol
    private let commentFilter: ProjectCommentFiltering

    init(
        commentService: ProjectCommentServiceProtocol,
        commentFilter: ProjectCommentFiltering
    ) {
        self.commentService = commentService
        self.commentFilter = commentFilter
    }

    func loadComments(
        versionID: String?,
        selectedFilePath: String?
    ) async throws -> ProjectCommentsSnapshot {
        guard let versionID else {
            return ProjectCommentsSnapshot(
                versionID: nil,
                versionComments: [],
                selectedFileComments: []
            )
        }

        let versionComments = try await commentService.fetchComments(versionID: versionID)
        let selectedFileComments = commentFilter.selectedFileComments(
            from: versionComments,
            selectedFilePath: selectedFilePath
        )

        return ProjectCommentsSnapshot(
            versionID: versionID,
            versionComments: versionComments,
            selectedFileComments: selectedFileComments
        )
    }

    func selectedFileComments(
        from versionComments: [Comment],
        selectedFilePath: String?
    ) -> [Comment] {
        commentFilter.selectedFileComments(
            from: versionComments,
            selectedFilePath: selectedFilePath
        )
    }

    func visibleTimelineComments(from comments: [Comment]) -> [Comment] {
        commentFilter.visibleTimelineComments(from: comments)
    }

    func commentsNear(timestampSeconds: Double, comments: [Comment], tolerance: Double) -> [Comment] {
        commentFilter.visibleTimelineComments(from: comments).filter { comment in
            guard let timestamp = comment.timestamp else { return false }
            return abs(timestamp - timestampSeconds) <= tolerance
        }
    }

    func commentMarkers(from comments: [Comment], fileID: String, duration: Double) -> [CommentMarker] {
        guard duration > 0 else { return [] }

        return commentFilter.visibleTimelineComments(from: comments).compactMap { comment in
            guard let timestamp = comment.timestamp else { return nil }
            let position = max(0, min(timestamp / duration, 1))

            return CommentMarker(
                id: comment.id,
                commentID: comment.id,
                fileID: comment.fileID ?? fileID,
                timestampSeconds: timestamp,
                position: position,
                previewText: comment.text
            )
        }
    }

    func addComment(_ input: ProjectCommentDraftInput) async throws {
        _ = try await commentService.addComment(
            projectID: input.projectID,
            branchID: input.branchID,
            versionID: input.versionID,
            filePath: input.filePath,
            text: input.text,
            timestamp: input.timestamp,
            userID: input.userID
        )
    }

    func updateCommentReview(commentID: String, state: CommentReviewState) async throws {
        try await commentService.updateCommentReview(
            commentID: commentID,
            reviewState: state,
            isHiddenFromTimeline: state == .accepted
        )
    }
}
