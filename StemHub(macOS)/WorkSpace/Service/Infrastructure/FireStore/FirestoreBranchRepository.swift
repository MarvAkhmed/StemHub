//
//  FirestoreBranchRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol
protocol FirestoreBranchStrategy {
    func fetchBranch(branchID: String) async throws -> Branch?
    func updateHeadVersionID(_ versionID: String, branchID: String) async throws
}

// MARK: - Implementation
final class DefaultFirestoreBranchStrategy: FirestoreBranchStrategy {

    private let db = Firestore.firestore()

    func fetchBranch(branchID: String) async throws -> Branch? {
        let doc = try await db.collection("branches").document(branchID).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: Branch.self)
    }

    func updateHeadVersionID(_ versionID: String, branchID: String) async throws {
        try await db.collection("branches")
            .document(branchID)
            .updateData(["headVersionID": versionID])
    }
}
