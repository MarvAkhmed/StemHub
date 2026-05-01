//
//  FirestoreCommentRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreCommentRepository: CommentRepository, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchComments(versionID: String) async throws -> [Comment] {
        let snapshot = try await db.collection(FirestoreCollections.comments.path)
            .whereField(FirestoreField.versionID.path, isEqualTo: versionID)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: Comment.self) }
            .sorted { lhs, rhs in
                if lhs.filePath == rhs.filePath {
                    let leftTimestamp = lhs.timestamp ?? -.greatestFiniteMagnitude
                    let rightTimestamp = rhs.timestamp ?? -.greatestFiniteMagnitude
                    if leftTimestamp == rightTimestamp {
                        return lhs.createdAt < rhs.createdAt
                    }
                    return leftTimestamp < rightTimestamp
                }
                return lhs.filePath.localizedCaseInsensitiveCompare(rhs.filePath) == .orderedAscending
            }
    }

    func addComment(_ comment: Comment) async throws {
        try db.collection(FirestoreCollections.comments.path).document(comment.id).setData(from: comment)
    }

    func fetchComments(projectID: String, fileID: String) async throws -> [Comment] {
        let snapshot = try await db.collection(FirestoreCollections.comments.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .whereField(FirestoreField.fileID.path, isEqualTo: fileID)
            .getDocuments()

        return try sortedComments(snapshot.documents.map { try $0.data(as: Comment.self) })
    }

    func saveComment(_ comment: Comment, projectID: String, fileID: String) async throws {
        try db.collection(FirestoreCollections.comments.path)
            .document(comment.id)
            .setData(from: comment)
    }

    func updateComment(_ comment: Comment, projectID: String, fileID: String) async throws {
        try db.collection(FirestoreCollections.comments.path)
            .document(comment.id)
            .setData(from: comment, merge: true)
    }

    func deleteComment(commentID: String, projectID: String, fileID: String) async throws {
        try await db.collection(FirestoreCollections.comments.path)
            .document(commentID)
            .delete()
    }

    func updateCommentReview(
        commentID: String,
        reviewState: CommentReviewState,
        isHiddenFromTimeline: Bool
    ) async throws {
        try await db.collection(FirestoreCollections.comments.path)
            .document(commentID)
            .updateData([
                FirestoreField.reviewState.path: reviewState.rawValue,
                FirestoreField.isHiddenFromTimeline.path: isHiddenFromTimeline
            ])
    }
}

private extension FirestoreCommentRepository {
    func sortedComments(_ comments: [Comment]) -> [Comment] {
        comments.sorted { lhs, rhs in
            if lhs.filePath == rhs.filePath {
                let leftTimestamp = lhs.timestamp ?? -.greatestFiniteMagnitude
                let rightTimestamp = rhs.timestamp ?? -.greatestFiniteMagnitude
                if leftTimestamp == rightTimestamp {
                    return lhs.createdAt < rhs.createdAt
                }
                return leftTimestamp < rightTimestamp
            }
            return lhs.filePath.localizedCaseInsensitiveCompare(rhs.filePath) == .orderedAscending
        }
    }
}
