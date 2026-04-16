//
//  FirestoreCommitRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol
protocol CommitStorageStrategy {
    /// Uploads changed files, creates blob/fileVersion/version docs, updates branch head.
    /// Returns the newly created ProjectVersion.
    func saveCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion
}

// MARK: - Implementation

final class DefaultCommitStorageStrategy: CommitStorageStrategy {
    
    private let db: Firestore
    private let uploadStrategy: FileUploadStrategy
    private let blobStrategy: FirestoreBlobStrategy
    private let branchStrategy: FirestoreBranchStrategy
    
    init(
        db: Firestore = Firestore.firestore(),
        uploadStrategy: FileUploadStrategy = FileUploadService(),
        blobStrategy: FirestoreBlobStrategy = DefaultFirestoreBlobStrategy(),
        branchStrategy: FirestoreBranchStrategy = DefaultFirestoreBranchStrategy()
    ) {
        self.db             = db
        self.uploadStrategy = uploadStrategy
        self.blobStrategy   = blobStrategy
        self.branchStrategy = branchStrategy
    }
    
    func saveCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        
        // 1. Upload every added/modified file and record its blob
        var fileVersionIDs: [String] = []
        
        for fileSnap in commit.fileSnapshot {
            let fileURL      = localRootURL.appendingPathComponent(fileSnap.path)
            let storagePath  = "projects/\(commit.projectID)/blobs/\(fileSnap.hash)"
            
            // Upload only if the file exists locally (added/modified)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                _ = try await uploadStrategy.uploadFile(localURL: fileURL, storagePath: storagePath)
                
                let blob = FileBlob(
                    id: fileSnap.hash,
                    storagePath: storagePath,
                    size: (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0,
                    hash: fileSnap.hash,
                    createdAt: .now
                )
                try await blobStrategy.saveBlob(blob)
            }
            
            // 2. Create a FileVersion document
            for fileSnapshot in commit.fileSnapshot {
                if fileSnapshot.path.hasSuffix("/") { continue }
                let blobID = fileSnapshot.hash
                
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
        }
        
        // 3. Save the Commit document itself
        try db.collection("commits").document(commit.id).setData(from: commit)
        
        // 4. Create the ProjectVersion
//        let versionID = UUID().uuidString
        
        // 2. Fetch branch
        let branchDoc = try await db.collection("branches").document(branchID).getDocument()
        guard let branch = try? branchDoc.data(as: Branch.self) else {
            throw SyncError.branchNotFound
        }
        // 4. Compute version number
        let parentVersionID = branch.headVersionID
        
        // 3. Prevent outdated commits
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
        
        // Create ProjectVersion
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
        
        // Update branch head
        try await branchStrategy.updateHeadVersionID(projectVersion.id, branchID: branchID)
        
        return projectVersion
    }
}
