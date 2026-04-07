//
//  DefaultFirestoreBranchStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore

protocol FirestoreBranchStrategy {
    func createBranch(projectID: String, name: String, fromBranchID: String?, userID: String) async throws -> Branch
    func fetchBranches(for projectID: String) async throws -> [Branch]
    func fetchBranch(branchID: String) async throws -> Branch?
    func updateBranchHead(branchID: String, versionID: String) async throws
}

struct DefaultFirestoreBranchStrategy: FirestoreBranchStrategy {
    private let db = Firestore.firestore()
    
    func createBranch(projectID: String, name: String, fromBranchID: String?, userID: String) async throws -> Branch {
        let branch = Branch(
            id: UUID().uuidString,
            projectID: projectID,
            name: name,
            headVersionID: nil,
            createdAt: Date(),
            createdBy: userID
        )
        try db.collection("branches").document(branch.id).setData(from: branch)
        
        if let fromBranchID = fromBranchID {
            let fromBranchDoc = try await db.collection("branches").document(fromBranchID).getDocument()
            let fromBranch = try fromBranchDoc.data(as: Branch.self)
            if let headVersionID = fromBranch.headVersionID {
                try await updateBranchHead(branchID: branch.id, versionID: headVersionID)
            }
        }
        
        return branch
    }
    
    func fetchBranches(for projectID: String) async throws -> [Branch] {
        let snapshot = try await db.collection("branches")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Branch.self) }
    }
    
    func fetchBranch(branchID: String) async throws -> Branch? {
        let doc = try await db.collection("branches").document(branchID).getDocument()
        return try? doc.data(as: Branch.self)
    }
    
    func updateBranchHead(branchID: String, versionID: String) async throws {
        try await db.collection("branches").document(branchID).updateData([
            "headVersionID": versionID
        ])
    }
}
