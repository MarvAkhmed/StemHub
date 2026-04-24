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

    func updateFolderReference(projectID: String, folderURL: URL) throws {
        try folderService.updateFolderReference(projectID: projectID, folderURL: folderURL)
    }

    func isProjectFolderWritable(projectID: String) -> Bool {
        guard let folderURL = folderService.resolveFolderURL(for: projectID) else {
            return false
        }

        return withScopedAccess(to: folderURL) {
            fileManager.isWritableFile(atPath: folderURL.path)
        }
    }

    func importAudioFiles(_ fileURLs: [URL], projectID: String) throws -> [URL] {
        guard let destinationRoot = folderService.resolveFolderURL(for: projectID) else {
            throw ProjectDetailError.missingProjectFolder
        }

        return try withScopedAccess(to: destinationRoot) {
            guard fileManager.isWritableFile(atPath: destinationRoot.path) else {
                throw ProjectDetailError.folderNotWritable
            }

            return try fileURLs.map { sourceURL in
                try withScopedAccess(to: sourceURL) {
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

    func loadLocalCommits(projectID: String) -> [LocalCommit] {
        localCommitStore
            .loadLocalCommitsAndCleanup(projectID: projectID)
            .sorted { $0.createdAt < $1.createdAt }
    }

    func saveLocalCommits(_ commits: [LocalCommit], projectID: String) {
        let sortedCommits = commits.sorted { $0.createdAt < $1.createdAt }
        localCommitStore.saveLocalCommits(sortedCommits, for: projectID)
    }

    func cacheCommit(_ commit: Commit, projectID: String) throws -> LocalCommit {
        guard let sourceRootURL = folderService.resolveFolderURL(for: projectID) else {
            throw ProjectDetailError.missingProjectFolder
        }

        let projectCacheFolder = localCommitStore.cacheFolder(for: projectID)
        let commitCacheFolder = projectCacheFolder.appendingPathComponent(commit.id, isDirectory: true)

        if fileManager.fileExists(atPath: commitCacheFolder.path) {
            try? fileManager.removeItem(at: commitCacheFolder)
        }

        try fileManager.createDirectory(at: commitCacheFolder, withIntermediateDirectories: true)

        try withScopedAccess(to: sourceRootURL) {
            for snapshot in commit.fileSnapshot {
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
            id: commit.id,
            commit: commit,
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

        return try withScopedAccess(to: currentFolderURL) {
            try withScopedAccess(to: destinationParentURL) {
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
    func withScopedAccess<T>(to url: URL, operation: () throws -> T) rethrows -> T {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }

    func uniqueDestinationURL(
        for fileName: String,
        in directoryURL: URL,
        preserveExtension: Bool = true
    ) -> URL {
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
