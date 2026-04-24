//
//  FirestoreCommentRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreCommentRepository: CommentRepository {
    private let db = Firestore.firestore()

    func fetchComments(
        projectID: String,
        branchID: String,
        versionID: String,
        filePath: String
    ) async throws -> [Comment] {
        let snapshot = try await db.collection("comments")
            .whereField("versionID", isEqualTo: versionID)
            .whereField("filePath", isEqualTo: filePath)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Comment.self) }
            .filter { $0.projectID == projectID && $0.branchID == branchID }
            .sorted { lhs, rhs in
                let leftTimestamp = lhs.timestamp ?? -.greatestFiniteMagnitude
                let rightTimestamp = rhs.timestamp ?? -.greatestFiniteMagnitude
                if leftTimestamp == rightTimestamp {
                    return lhs.createdAt < rhs.createdAt
                }
                return leftTimestamp < rightTimestamp
            }
    }

    func fetchComments(versionID: String) async throws -> [Comment] {
        let snapshot = try await db.collection("comments")
            .whereField("versionID", isEqualTo: versionID)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Comment.self) }
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
        try db.collection("comments").document(comment.id).setData(from: comment)
    }

    func updateCommentReview(
        commentID: String,
        reviewState: CommentReviewState,
        isHiddenFromTimeline: Bool
    ) async throws {
        try await db.collection("comments")
            .document(commentID)
            .updateData([
                "reviewState": reviewState.rawValue,
                "isHiddenFromTimeline": isHiddenFromTimeline
            ])
    }
}
