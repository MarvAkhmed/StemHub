//
//  TimestampedCommentService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct TimestampedCommentContext: Sendable {
    let projectID: String
    let branchID: String
    let versionID: String
    let fileID: String
    let filePath: String
    let userID: String
}

protocol TimestampedCommentServing: Sendable {
    func comments(projectID: String, fileID: String) async throws -> [Comment]

    func addComment(
        context: TimestampedCommentContext,
        timestampSeconds: Double,
        text: String
    ) async throws -> Comment

    func updateComment(
        _ comment: Comment,
        text: String
    ) async throws -> Comment

    func deleteComment(_ comment: Comment) async throws

    func resolveComment(_ comment: Comment) async throws -> Comment

    func commentsNear(
        timestampSeconds: Double,
        fileID: String,
        comments: [Comment],
        tolerance: Double
    ) -> [Comment]
}

final class TimestampedCommentService: TimestampedCommentServing, @unchecked Sendable {
    private let repository: TimestampedCommentRepository

    init(repository: TimestampedCommentRepository) {
        self.repository = repository
    }

    func comments(projectID: String, fileID: String) async throws -> [Comment] {
        try await repository.fetchComments(projectID: projectID, fileID: fileID)
    }

    func addComment(
        context: TimestampedCommentContext,
        timestampSeconds: Double,
        text: String
    ) async throws -> Comment {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TimestampedCommentServiceError.emptyComment
        }

        let comment = Comment(
            id: UUID().uuidString,
            projectID: context.projectID,
            branchID: context.branchID,
            versionID: context.versionID,
            fileID: context.fileID,
            filePath: context.filePath,
            userID: context.userID,
            timestamp: timestampSeconds,
            rangeStart: nil,
            rangeEnd: nil,
            text: trimmedText,
            createdAt: Date()
        )

        try await repository.saveComment(
            comment,
            projectID: context.projectID,
            fileID: context.fileID
        )
        return comment
    }

    func updateComment(
        _ comment: Comment,
        text: String
    ) async throws -> Comment {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TimestampedCommentServiceError.emptyComment
        }

        let updated = Comment(
            id: comment.id,
            projectID: comment.projectID,
            branchID: comment.branchID,
            versionID: comment.versionID,
            fileID: comment.fileID,
            filePath: comment.filePath,
            userID: comment.userID,
            timestamp: comment.timestamp,
            rangeStart: comment.rangeStart,
            rangeEnd: comment.rangeEnd,
            text: trimmedText,
            createdAt: comment.createdAt,
            updatedAt: Date(),
            reviewState: comment.reviewState,
            isHiddenFromTimeline: comment.isHiddenFromTimeline
        )

        try await repository.updateComment(
            updated,
            projectID: updated.projectID,
            fileID: resolvedFileID(for: updated)
        )
        return updated
    }

    func deleteComment(_ comment: Comment) async throws {
        try await repository.deleteComment(
            commentID: comment.id,
            projectID: comment.projectID,
            fileID: resolvedFileID(for: comment)
        )
    }

    func resolveComment(_ comment: Comment) async throws -> Comment {
        var resolved = comment
        resolved.reviewState = .accepted
        resolved.isHiddenFromTimeline = true
        resolved.updatedAt = Date()

        try await repository.updateComment(
            resolved,
            projectID: resolved.projectID,
            fileID: resolvedFileID(for: resolved)
        )
        return resolved
    }

    func commentsNear(
        timestampSeconds: Double,
        fileID: String,
        comments: [Comment],
        tolerance: Double
    ) -> [Comment] {
        comments.filter { comment in
            guard comment.fileID == nil || comment.fileID == fileID,
                  let timestamp = comment.timestamp,
                  comment.isHiddenFromTimeline == false else {
                return false
            }

            return abs(timestamp - timestampSeconds) <= tolerance
        }
    }
}

private extension TimestampedCommentService {
    func resolvedFileID(for comment: Comment) -> String {
        comment.fileID ?? comment.filePath
    }
}

enum TimestampedCommentServiceError: LocalizedError {
    case emptyComment

    var errorDescription: String? {
        switch self {
        case .emptyComment:
            return "Comment text cannot be empty."
        }
    }
}
