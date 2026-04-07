//
//  ProjectSyncService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

protocol ProjectSyncService {
    func pull(projectID: String, branchID: String, localPath: String) async throws -> LocalProjectState
    func createCommit(projectID: String, branchID: String, localPath: String, lastPulledVersionID: String?, files: [LocalFile], userID: String, message: String) async throws -> Commit
    func pushCommit(_ commit: Commit, branchID: String, localRootURL: URL) async throws -> ProjectVersion
    func rebaseCommit(_ localCommit: LocalCommit, onto newBaseVersionID: String, projectID: String) async throws -> LocalCommit
}

final class DefaultProjectSyncService: ProjectSyncService {
    private let syncOrchestrator: SyncOrchestrator
    private let network: ProjectNetworkStrategy
    private let persistence: ProjectPersistenceStrategy
    
    init(syncOrchestrator: SyncOrchestrator = SyncOrchestrator(),
         network: ProjectNetworkStrategy = DefaultProjectNetworkStrategy(),
         persistence: ProjectPersistenceStrategy = DefaultProjectPersistenceStrategy()) {
        self.syncOrchestrator = syncOrchestrator
        self.network = network
        self.persistence = persistence
    }
    
    func pull(projectID: String, branchID: String, localPath: String) async throws -> LocalProjectState {
        let state = LocalProjectState(
            projectID: projectID,
            localPath: localPath,
            lastPulledVersionID: persistence.getLastPulledVersionID(for: projectID),
            lastCommittedID: nil,
            currentBranchID: branchID
        )
        return try await syncOrchestrator.pullProject(
            projectID: projectID,
            branchID: branchID,
            localRootURL: URL(fileURLWithPath: localPath),
            state: state
        )
    }
    
    func createCommit(projectID: String, branchID: String, localPath: String, lastPulledVersionID: String?, files: [LocalFile], userID: String, message: String) async throws -> Commit {
        let state = LocalProjectState(
            projectID: projectID,
            localPath: localPath,
            lastPulledVersionID: lastPulledVersionID,
            lastCommittedID: nil,
            currentBranchID: branchID
        )
        let remoteSnapshot = try await network.fetchRemoteSnapshot(versionID: lastPulledVersionID ?? "")
        return try await syncOrchestrator.commit(
            localPath: URL(fileURLWithPath: localPath),
            localState: state,
            remoteSnapshot: remoteSnapshot,
            userID: userID,
            message: message
        )
    }
    
    func pushCommit(_ commit: Commit, branchID: String, localRootURL: URL) async throws -> ProjectVersion {
        return try await syncOrchestrator.pushCommit(commit, localRootURL: localRootURL, branchID: branchID)
    }
    
    func rebaseCommit(_ localCommit: LocalCommit, onto newBaseVersionID: String, projectID: String) async throws -> LocalCommit {
        let remoteSnapshot = try await network.fetchRemoteSnapshot(versionID: newBaseVersionID)
        
        var localFiles: [LocalFile] = []
        for snapshot in localCommit.commit.fileSnapshot {
            let fileURL = localCommit.cachedFolderURL.appendingPathComponent(snapshot.path)
            let hash = LocalFileScanner.hashFile(at: fileURL)
            let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
            let localFile = LocalFile(
                path: snapshot.path,
                name: (snapshot.path as NSString).lastPathComponent,
                fileExtension: (snapshot.path as NSString).pathExtension,
                size: size,
                hash: hash,
                isDirectory: false
            )
            localFiles.append(localFile)
        }
        
        let diffEngine = DefaultDiffEngineStrategy()
        let diffResult = diffEngine.computeDiff(local: localFiles, remote: remoteSnapshot)
        let newDiff = diffEngine.mapToProjectDiff(diffResult)
        
        let newCommitID = UUID().uuidString
        
        // Get the project's commit cache folder (parent of the original commit folder)
        let projectCacheFolder = localCommit.cachedFolderURL.deletingLastPathComponent()
        let newCacheFolder = projectCacheFolder.appendingPathComponent(newCommitID, isDirectory: true)
        
        // Create the new cache folder
        try FileManager.default.createDirectory(at: newCacheFolder, withIntermediateDirectories: true)
        
        // Copy all files to new cache folder
        for snapshot in localCommit.commit.fileSnapshot {
            let src = localCommit.cachedFolderURL.appendingPathComponent(snapshot.path)
            let dst = newCacheFolder.appendingPathComponent(snapshot.path)
            try FileManager.default.copyItem(at: src, to: dst)
        }
        
        let rebasedCommit = Commit(
            id: newCommitID,
            projectID: localCommit.commit.projectID,
            parentCommitID: localCommit.commit.parentCommitID,
            basedOnVersionID: newBaseVersionID,
            diff: newDiff,
            fileSnapshot: localCommit.commit.fileSnapshot,
            createdBy: localCommit.commit.createdBy,
            createdAt: Date(),
            message: localCommit.commit.message,
            status: .local
        )
        
        // Delete the old commit folder (it's being replaced)
        try? FileManager.default.removeItem(at: localCommit.cachedFolderURL)
        
        return LocalCommit(
            id: newCommitID,
            commit: rebasedCommit,
            cachedFolderURL: newCacheFolder,
            isPushed: false,
            createdAt: Date()
        )
    }
}
