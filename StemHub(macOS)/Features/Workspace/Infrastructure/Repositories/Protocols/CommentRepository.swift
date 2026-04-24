//
//  CommentRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol CommentRepository {
    func fetchComments(
        projectID: String,
        branchID: String,
        versionID: String,
        filePath: String
    ) async throws -> [Comment]
    func fetchComments(versionID: String) async throws -> [Comment]

    func addComment(_ comment: Comment) async throws
    func updateCommentReview(
        commentID: String,
        reviewState: CommentReviewState,
        isHiddenFromTimeline: Bool
    ) async throws
}
