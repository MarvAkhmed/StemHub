//
//  CommentRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol RemoteCommentRepository: Sendable {
    func fetchComments(versionID: String) async throws -> [Comment]

    func addComment(_ comment: Comment) async throws
    func updateCommentReview(commentID: String,
                             reviewState: CommentReviewState,
                             isHiddenFromTimeline: Bool) async throws
}

protocol TimestampedCommentRepository: Sendable {
    func fetchComments(projectID: String, fileID: String) async throws -> [Comment]
    func saveComment(_ comment: Comment, projectID: String, fileID: String) async throws
    func updateComment(_ comment: Comment, projectID: String, fileID: String) async throws
    func deleteComment(commentID: String, projectID: String, fileID: String) async throws
}

protocol CommentRepository:
    RemoteCommentRepository,
    TimestampedCommentRepository {}
