//
//  ProjectLocalWorkspaceService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

actor ProjectLocalWorkspaceService {
    private let folderService: any ProjectLocalWorkspaceFolderAccessing
    private let localCommitStore: LocalCommitStore
    private let fileManager = FileManager.default

    init(
        folderService: any ProjectLocalWorkspaceFolderAccessing,
        localCommitStore: LocalCommitStore
    ) {
        self.folderService = folderService
        self.localCommitStore = localCommitStore
    }

    func resolveFolderURL(projectID: String) -> URL? {
        folderService.resolveFolderURL(for: projectID)
    }

    func loadFileTree(projectID: String) -> [FileTreeNode] {
        folderService.fileTree(for: projectID)
    }

    func relativePath(for fileURL: URL, projectID: String) -> String? {
        folderService.relativePath(for: fileURL, projectID: projectID)
    }

    func existingFileURL(relativePath: String, projectID: String) -> URL? {
        guard let folderURL = folderService.resolveFolderURL(for: projectID) else {
            return nil
        }

        return folderURL.withSecurityScopedAccess {
            let resolvedURL = folderURL.appendingPathComponent(relativePath)
            return fileManager.fileExists(atPath: resolvedURL.path) ? resolvedURL : nil
        }
    }

    func updateFolderReference(projectID: String, folderURL: URL) throws {
        try folderService.updateFolderReference(projectID: projectID, folderURL: folderURL)
    }

    func isProjectFolderWritable(projectID: String) -> Bool {
        guard let folderURL = folderService.resolveFolderURL(for: projectID) else {
            return false
        }

        return folderURL.withSecurityScopedAccess {
            fileManager.isWritableFile(atPath: folderURL.path)
        }
    }

    func ensureProjectFolderWritable(projectID: String) throws {
        guard let folderURL = folderService.resolveFolderURL(for: projectID) else {
            throw ProjectDetailError.missingProjectFolder
        }

        let isWritable = folderURL.withSecurityScopedAccess {
            fileManager.isWritableFile(atPath: folderURL.path)
        }

        guard isWritable else {
            throw ProjectDetailError.folderNotWritable
        }
    }

    func importAudioFiles(_ fileURLs: [URL], projectID: String) throws -> [URL] {
        guard let destinationRoot = folderService.resolveFolderURL(for: projectID) else {
            throw ProjectDetailError.missingProjectFolder
        }

        return try destinationRoot.withSecurityScopedAccess {
            guard fileManager.isWritableFile(atPath: destinationRoot.path) else {
                throw ProjectDetailError.folderNotWritable
            }

            return try fileURLs.map { sourceURL in
                try sourceURL.withSecurityScopedAccess {
                    let destinationURL = uniqueDestinationURL(
                        for: sourceURL.lastPathComponent,
                        in: destinationRoot
                    )
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                    return destinationURL
                }
            }
        }
    }

    func loadLocalCommits(projectID: String) throws -> [LocalCommit]  {
        try localCommitStore
            .loadLocalCommitsAndCleanup(projectID: projectID)
            .sorted { $0.createdAt < $1.createdAt }
    }

    func latestLocalCommitID(projectID: String) throws -> String? {
        try loadLocalCommits(projectID: projectID).last?.id
    }

    func saveLocalCommits(_ commits: [LocalCommit], projectID: String) throws {
        let sortedCommits = commits.sorted { $0.createdAt < $1.createdAt }
        try localCommitStore.saveLocalCommits(sortedCommits, for: projectID)
    }

    func stageCommit(_ commit: Commit, projectID: String) throws -> [LocalCommit] {
        var commits = try loadLocalCommits(projectID: projectID)
        let parentCommitID = commit.parentCommitID ?? commits.last?.id
        let localCommit = try cacheCommit(
            commit,
            projectID: projectID,
            parentCommitID: parentCommitID
        )

        commits.removeAll { $0.id == localCommit.id }
        commits.append(localCommit)

        let sortedCommits = commits.sorted { $0.createdAt < $1.createdAt }
        try localCommitStore.saveLocalCommits(sortedCommits, for: projectID)
        return sortedCommits
    }

    func removeCommit(id commitID: String, projectID: String) throws -> [LocalCommit] {
        var commits = try loadLocalCommits(projectID: projectID)
        commits.removeAll { $0.id == commitID }

        let sortedCommits = commits.sorted { $0.createdAt < $1.createdAt }
        try localCommitStore.saveLocalCommits(sortedCommits, for: projectID)
        return sortedCommits
    }

    func cacheCommit(
        _ commit: Commit,
        projectID: String,
        parentCommitID: String?
    ) throws -> LocalCommit {
        guard let sourceRootURL = folderService.resolveFolderURL(for: projectID) else {
            throw ProjectDetailError.missingProjectFolder
        }

        let commitToCache = commitWithParent(commit, parentCommitID: parentCommitID)
        let projectCacheFolder = try localCommitStore.cacheFolder(for: projectID)
        let commitCacheFolder = projectCacheFolder.appendingPathComponent(commitToCache.id, isDirectory: true)

        if fileManager.fileExists(atPath: commitCacheFolder.path) {
            try? fileManager.removeItem(at: commitCacheFolder)
        }

        try fileManager.createDirectory(at: commitCacheFolder, withIntermediateDirectories: true)

        try sourceRootURL.withSecurityScopedAccess {
            for snapshot in commitToCache.fileSnapshot {
                let sourceURL = sourceRootURL.appendingPathComponent(snapshot.path)
                guard fileManager.fileExists(atPath: sourceURL.path) else { continue }

                let destinationURL = commitCacheFolder.appendingPathComponent(snapshot.path)
                try fileManager.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }
        }

        return LocalCommit(
            id: commitToCache.id,
            parentCommitID: parentCommitID,
            commit: commitToCache,
            cachedFolderURL: commitCacheFolder,
            isPushed: false,
            createdAt: Date()
        )
    }

    func relocateProjectFolder(
        projectID: String,
        destinationParentURL: URL
    ) throws -> URL {
        guard let currentFolderURL = folderService.resolveFolderURL(for: projectID) else {
            throw ProjectDetailError.missingProjectFolder
        }

        let standardizedCurrentURL = currentFolderURL.standardizedFileURL
        let standardizedParentURL = destinationParentURL.standardizedFileURL

        if standardizedCurrentURL.deletingLastPathComponent() == standardizedParentURL {
            try folderService.updateFolderReference(projectID: projectID, folderURL: standardizedCurrentURL)
            return standardizedCurrentURL
        }

        return try currentFolderURL.withSecurityScopedAccess {
            try destinationParentURL.withSecurityScopedAccess {
                let destinationURL = uniqueDestinationURL(
                    for: standardizedCurrentURL.lastPathComponent,
                    in: standardizedParentURL,
                    preserveExtension: false
                )
                try fileManager.moveItem(at: standardizedCurrentURL, to: destinationURL)
                try folderService.updateFolderReference(projectID: projectID, folderURL: destinationURL)
                return destinationURL
            }
        }
    }
}

private extension ProjectLocalWorkspaceService {
    func commitWithParent(_ commit: Commit, parentCommitID: String?) -> Commit {
        Commit(
            id: commit.id,
            projectID: commit.projectID,
            parentCommitID: parentCommitID,
            basedOnVersionID: commit.basedOnVersionID,
            diff: commit.diff,
            fileSnapshot: commit.fileSnapshot,
            createdBy: commit.createdBy,
            createdAt: commit.createdAt,
            message: commit.message,
            status: commit.status
        )
    }
    func uniqueDestinationURL(for fileName: String,
                              in directoryURL: URL,
                              preserveExtension: Bool = true) -> URL {

        let nsFileName = fileName as NSString
        let baseName = preserveExtension ? nsFileName.deletingPathExtension : fileName
        let fileExtension = preserveExtension ? nsFileName.pathExtension : ""

        var index = 0
        var candidateURL: URL

        repeat {
            let suffix = index == 0 ? "" : " \(index)"
            let candidateName = preserveExtension && !fileExtension.isEmpty
                ? "\(baseName)\(suffix).\(fileExtension)"
                : "\(baseName)\(suffix)"
            candidateURL = directoryURL.appendingPathComponent(candidateName, isDirectory: !preserveExtension)
            index += 1
        } while fileManager.fileExists(atPath: candidateURL.path)

        return candidateURL
    }
}
