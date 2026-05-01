//
//  ProjectCommentService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol ProjectCommentServiceProtocol {
    func fetchComments(versionID: String) async throws -> [Comment]

    func addComment(
        projectID: String,
        branchID: String,
        versionID: String,
        filePath: String,
        text: String,
        timestamp: Double?,
        userID: String
    ) async throws -> Comment
    func updateCommentReview(
        commentID: String,
        reviewState: CommentReviewState,
        isHiddenFromTimeline: Bool
    ) async throws
}

final class ProjectCommentService: ProjectCommentServiceProtocol {
    private let commentRepository: CommentRepository

    init(commentRepository: CommentRepository) {
        self.commentRepository = commentRepository
    }

    func fetchComments(versionID: String) async throws -> [Comment] {
        try await commentRepository.fetchComments(versionID: versionID)
    }

    func addComment(
        projectID: String,
        branchID: String,
        versionID: String,
        filePath: String,
        text: String,
        timestamp: Double?,
        userID: String
    ) async throws -> Comment {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw ValidationError.emptyComment
        }

        let comment = Comment(
            id: UUID().uuidString,
            projectID: projectID,
            branchID: branchID,
            versionID: versionID,
            filePath: filePath,
            userID: userID,
            timestamp: timestamp,
            rangeStart: nil,
            rangeEnd: nil,
            text: trimmedText,
            createdAt: Date()
        )

        try await commentRepository.addComment(comment)
        return comment
    }

    func updateCommentReview(
        commentID: String,
        reviewState: CommentReviewState,
        isHiddenFromTimeline: Bool
    ) async throws {
        try await commentRepository.updateCommentReview(
            commentID: commentID,
            reviewState: reviewState,
            isHiddenFromTimeline: isHiddenFromTimeline
        )
    }
}

private enum ValidationError: LocalizedError {
    case emptyComment

    var errorDescription: String? {
        switch self {
        case .emptyComment:
            return "Comment text cannot be empty."
        }
    }
}
