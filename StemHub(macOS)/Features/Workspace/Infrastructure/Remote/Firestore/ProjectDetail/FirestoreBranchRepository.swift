//
//  FirestoreBranchRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreBranchRepository: BranchRepository, @unchecked Sendable {
    private let db: Firestore
    
    init(db: Firestore) {
        self.db = db
    }
    
    func fetchBranches(projectID: String) async throws -> [Branch] {
        let snapshot = try await db.collection(FirestoreCollections.branches.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .order(by: FirestoreField.createdAt.path, descending: false)
            .getDocuments()
        
        return try snapshot.documents.map { try $0.data(as: Branch.self) }
    }
    
    func fetchBranch(branchID: String) async throws -> Branch? {
        let doc = try await db.collection(FirestoreCollections.branches.path)
            .document(branchID)
            .getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: Branch.self)
    }
    
    func fetchHeadVersionID(branchID: String) async throws -> String? {
        try await fetchBranch(branchID: branchID)?.headVersionID
    }
    
    func createBranch(projectID: String,
                      name: String,
                      headVersionID: String?,
                      createdBy: String
    ) async throws -> Branch {
        
        
        if let headVersionID {
            try await validateHeadVersion(headVersionID, belongsTo: projectID)
        }
        
        let branch = Branch(
            id: UUID().uuidString,
            projectID: projectID,
            name: name,
            headVersionID: headVersionID,
            createdAt: Date(),
            createdBy: createdBy
        )
        
        try db.collection(FirestoreCollections.branches.path)
            .document(branch.id)
            .setData(from: branch)
        return branch
    }
}

private extension FirestoreBranchRepository {
    func validateHeadVersion(_ versionID: String, belongsTo projectID: String) async throws {
        let versionDoc = try await db
            .collection(FirestoreCollections.projectVersions.path)
            .document(versionID)
            .getDocument()

        guard versionDoc.exists,
              let version = try? versionDoc.data(as: ProjectVersion.self),
              version.projectID == projectID
        else {
            throw SyncError.projectNotFound
        }
    }
}

// VERIFICATION
// - [ ] createBranch with a valid in-project headVersionID succeeds and returns the Branch.
// - [ ] createBranch with a headVersionID that does not exist in Firestore throws
//       SyncError.projectNotFound.
// - [ ] createBranch with a headVersionID belonging to a different projectID throws
//       SyncError.projectNotFound.
// - [ ] createBranch with headVersionID == nil succeeds without any Firestore read
//       for version validation.
// - [ ] The function signature is identical to the original — no new parameters added.
// - [ ] A failed validation never writes a Branch document to Firestore.
