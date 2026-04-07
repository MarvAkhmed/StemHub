//
//  CommitStorageService.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

protocol CommitStorageStrategy {
    func saveCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion
    func fetchCommit(commitID: String) async throws -> Commit?
}

struct DefaultCommitStorageStrategy: CommitStorageStrategy {
    private let db = Firestore.firestore()
    private let uploadStrategy: FileUploadStrategy
    
    init(uploadStrategy: FileUploadStrategy = FileUploadService()) {
        self.uploadStrategy = uploadStrategy
    }
    
    func saveCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        var fileVersionIDs: [String] = []
          
        for fileSnapshot in commit.fileSnapshot {
            if fileSnapshot.path.hasSuffix("/") { continue }
            
            let blobID = fileSnapshot.hash
            
            //  Assume the blob already exists in Firestore and Storage
            // Just create the fileVersion
            let fileVersion = FileVersion(
                id: UUID().uuidString,
                fileID: fileSnapshot.fileID,
                blobID: blobID,
                path: fileSnapshot.path,
                versionNumber: fileSnapshot.versionNumber,
                syncStatus: .synced,
                createdAt: Date()
            )
            try db.collection("fileVersions").document(fileVersion.id).setData(from: fileVersion)
            fileVersionIDs.append(fileVersion.id)
        }
        
        
        let branchDoc = try await db.collection("branches").document(branchID).getDocument()
        guard let branch = try? branchDoc.data(as: Branch.self) else {
            throw SyncError.branchNotFound
        }
        
        let parentVersionID = branch.headVersionID
        
        if parentVersionID != commit.basedOnVersionID && parentVersionID != nil {
            throw SyncError.outdatedCommit
        }
        
        let versionNumber: Int
        if let parentID = parentVersionID {
            let parentDoc = try await db.collection("projectVersions").document(parentID).getDocument()
            let parentVersion = try parentDoc.data(as: ProjectVersion.self)
            versionNumber = parentVersion.versionNumber + 1
        } else {
            versionNumber = 1
        }
        
        let projectVersion = ProjectVersion(
            id: UUID().uuidString,
            projectID: commit.projectID,
            versionNumber: versionNumber,
            parentVersionID: parentVersionID,
            fileVersionIDs: fileVersionIDs,
            createdBy: commit.createdBy,
            createdAt: Date(),
            notes: commit.message,
            diff: commit.diff,
            commitId: commit.id
        )
        
        try db.collection("projectVersions").document(projectVersion.id).setData(from: projectVersion)
        
        try await db.collection("branches").document(branchID).updateData([
            "headVersionID": projectVersion.id
        ])
        
        let projectDoc = try await db.collection("projects").document(commit.projectID).getDocument()
        if let project = try? projectDoc.data(as: Project.self), project.currentBranchID == branchID {
            try await db.collection("projects").document(project.id).updateData([
                "currentVersionID": projectVersion.id,
                "updatedAt": Date()
            ])
        }
        
        return projectVersion
    }
    
    func fetchCommit(commitID: String) async throws -> Commit? {
        let doc = try await db.collection("commits").document(commitID).getDocument()
        return try? doc.data(as: Commit.self)
    }
}
