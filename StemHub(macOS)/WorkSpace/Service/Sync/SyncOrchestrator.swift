//
//  SyncOrchestrator.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

enum SyncError: Error {
    case branchNotFound, projectNotFound, outdatedCommit
}

final class SyncOrchestrator {
    private let scanStrategy: FileScanStrategy
    private let diffStrategy: DiffEngineStrategy
    private let commitStorage: CommitStorageStrategy
    private let remoteFetch: RemoteFetchStrategy
    private let fileUploadStrategy: FileUploadStrategy
    
    init(
        scanStrategy: FileScanStrategy = LocalFileScanner(),
        diffStrategy: DiffEngineStrategy = DefaultDiffEngineStrategy(),
        commitStorage: CommitStorageStrategy = DefaultCommitStorageStrategy(),
        remoteFetch: RemoteFetchStrategy = FirestoreRemoteFetch(),
        fileUploadStrategy: FileUploadStrategy = FileUploadService()
    ) {
        self.scanStrategy = scanStrategy
        self.diffStrategy = diffStrategy
        self.commitStorage = commitStorage
        self.remoteFetch = remoteFetch
        self.fileUploadStrategy = fileUploadStrategy
    }
    
    func commit(localPath: URL,localState: LocalProjectState,remoteSnapshot: [RemoteFileSnapshot],
        userID: String, message: String? ) async throws -> Commit {
        let localFiles = try scanStrategy.scan(folderURL: localPath)
        let diffResult = diffStrategy.computeDiff(local: localFiles, remote: remoteSnapshot)
        let projectDiff = diffStrategy.mapToProjectDiff(diffResult)
        
        let snapshot: [CommitFileSnapshot] = localFiles
            .filter { !$0.isDirectory }
            .map {
                CommitFileSnapshot(
                    fileID: UUID().uuidString,
                    path: $0.path,
                    blobID: "",
                    hash: $0.hash,
                    versionNumber: 1
                )
            }
        
        let commit = Commit(
            id: UUID().uuidString,
            projectID: localState.projectID,
            parentCommitID: localState.lastCommittedID,
            basedOnVersionID: localState.lastPulledVersionID ?? "",
            diff: projectDiff,
            fileSnapshot: snapshot,
            createdBy: userID,
            createdAt: Date(),
            message: message ?? "Auto commit",
            status: .local
        )
        
        return commit
    }
    
    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion {
        return try await commitStorage.saveCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }
    
    func pullProject(
        projectID: String,
        branchID: String,
        localRootURL: URL,
        state: LocalProjectState
    ) async throws -> LocalProjectState {
        var updatedState = state
        
        let branchDoc = try await Firestore.firestore().collection("branches").document(branchID).getDocument()
        guard let branch = try? branchDoc.data(as: Branch.self) else {
            throw SyncError.branchNotFound
        }
        
        guard let latestVersionID = branch.headVersionID else {
            return updatedState
        }
        
        if updatedState.lastPulledVersionID == latestVersionID {
            return updatedState
        }
        
        guard let projectVersion = try await remoteFetch.fetchProjectVersion(versionID: latestVersionID) else {
            throw SyncError.projectNotFound
        }
        
        var fileVersions: [FileVersion] = []
        for id in projectVersion.fileVersionIDs {
            let doc = try await Firestore.firestore().collection("fileVersions").document(id).getDocument()
            let fv = try doc.data(as: FileVersion.self)
            fileVersions.append(fv)
        }
        
        var blobs: [String: FileBlob] = [:]
        for fileVersion in fileVersions {
            let blobDoc = try await Firestore.firestore().collection("blobs").document(fileVersion.blobID).getDocument()
            let blob = try blobDoc.data(as: FileBlob.self)
            blobs[fileVersion.blobID] = blob
        }
        print("🔍 Diff files to apply:")
        for diff in projectVersion.diff.files {
            print("   \(diff.changeType): \(diff.path)")
            let filePath = localRootURL.appendingPathComponent(diff.path)
            print("🗑️ PULL REMOVED: \(filePath.path)")
            
       
            switch diff.changeType {
            case .added, .modified:
                guard let newHash = diff.newHash, let blob = blobs[newHash] else { continue }
                let dir = filePath.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                try? FileManager.default.removeItem(at: filePath)
                try await fileUploadStrategy.downloadFile(storagePath: blob.storagePath, to: filePath)
                
            case .removed:
                if FileManager.default.fileExists(atPath: filePath.path) {
                    print("🗑️ ACTUALLY DELETING FILE: \(filePath.path)")
                    if FileManager.default.fileExists(atPath: filePath.path) {
                        try FileManager.default.removeItem(at: filePath)
                    }
                }
                
            case .renamed:
                guard let oldPath = diff.oldPath else { continue }
                let oldURL = localRootURL.appendingPathComponent(oldPath)
                if FileManager.default.fileExists(atPath: oldURL.path) {
                    let dir = filePath.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    try FileManager.default.moveItem(at: oldURL, to: filePath)
                }
            }
        }
        
        updatedState.lastPulledVersionID = latestVersionID
        return updatedState
    }
}
