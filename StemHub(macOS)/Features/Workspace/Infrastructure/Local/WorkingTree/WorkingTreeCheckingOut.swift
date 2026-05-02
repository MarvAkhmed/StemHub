//
//  LocalWorkingTreeCheckoutService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

protocol WorkingTreeCheckingOut: Sendable {
    func hasLocalChanges(localRootURL: URL,
                         remoteSnapshot: [RemoteFileSnapshot]) async throws -> Bool

    func checkout(_ files: [WorkingTreeCheckoutFile], at localRootURL: URL) async throws
}

actor LocalWorkingTreeCheckoutService: WorkingTreeCheckingOut {
    private let localFileSnapshotProvider: LocalFileSnapshotProviding
    private let diffStrategy: DiffEngineStrategy
    private let fileTransferStrategy: RemoteFileTransferStrategy
    nonisolated(unsafe) private let fileManager: FileManager

    init(
        localFileSnapshotProvider: LocalFileSnapshotProviding,
        diffStrategy: DiffEngineStrategy,
        fileTransferStrategy: RemoteFileTransferStrategy,
        fileManager: FileManager = .default
    ) {
        self.localFileSnapshotProvider = localFileSnapshotProvider
        self.diffStrategy = diffStrategy
        self.fileTransferStrategy = fileTransferStrategy
        self.fileManager = fileManager
    }
    
    func hasLocalChanges(
        localRootURL: URL,
        remoteSnapshot: [RemoteFileSnapshot]
    ) async throws -> Bool {
        let localFiles = try await localFileSnapshotProvider.scan(folderURL: localRootURL)
            .filter { !$0.isDirectory }

        return diffStrategy
            .computeDiff(local: localFiles, remote: remoteSnapshot)
            .hasChanges
    }

    func checkout(_ files: [WorkingTreeCheckoutFile], at localRootURL: URL) async throws {
        try await localRootURL.withSecurityScopedAccess {
            try await replaceWorkingTree(with: files, at: localRootURL)
        }
    }
}

private struct StagedWorkingTreeFile: Sendable {
    let path: String
    let url: URL
}

private struct WorkingTreeBackup: Sendable {
    let path: String
    let url: URL
}

private extension LocalWorkingTreeCheckoutService {
    func replaceWorkingTree(with files: [WorkingTreeCheckoutFile], at localRootURL: URL) async throws {
        let tempRootURL = fileManager.temporaryDirectory
            .appendingPathComponent("StemHubCheckout-\(UUID().uuidString)", isDirectory: true)
        let stagedRootURL = tempRootURL.appendingPathComponent("staged", isDirectory: true)
        let backupRootURL = tempRootURL.appendingPathComponent("backup", isDirectory: true)

        try fileManager.createDirectory(at: stagedRootURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: backupRootURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempRootURL) }

        let localFiles = try await localFileSnapshotProvider.scan(folderURL: localRootURL)
            .filter { !$0.isDirectory }
        let localFilesByPath = Dictionary(localFiles.map { ($0.path, $0) }, uniquingKeysWith: { $1 })
        let targetPaths = Set(files.map(\.path))
        let obsoletePaths = Set(localFiles.map(\.path)).subtracting(targetPaths)
        let stagedFiles = try await stageFiles(
            files,
            localFilesByPath: localFilesByPath,
            stagedRootURL: stagedRootURL
        )
        let mutationPaths = obsoletePaths.union(stagedFiles.map(\.path))
        let backups = try backupExistingItems(
            paths: mutationPaths,
            from: localRootURL,
            to: backupRootURL
        )

        do {
            try install(stagedFiles, in: localRootURL, backedUpPaths: Set(backups.map(\.path)))
            try removeEmptyDirectories(in: localRootURL)
        } catch {
            do {
                try restore(backups, to: localRootURL)
            } catch let restoreError {
                throw WorkingTreeError.checkoutAndRestoreFailed(
                    checkoutError: error,
                    restoreError: restoreError
                )
            }
            throw error
        }
    }

    func stageFiles(_ files: [WorkingTreeCheckoutFile], localFilesByPath: [String: LocalFile],
                    stagedRootURL: URL) async throws -> [StagedWorkingTreeFile] {
        try await withThrowingTaskGroup(of: StagedWorkingTreeFile?.self) { group in
            for file in files {
                group.addTask { [fileManager, fileTransferStrategy] in
                    guard localFilesByPath[file.path]?.fileHash != file.blobID else {
                        return nil
                    }

                    let stagedURL = stagedRootURL.appendingPathComponent(file.path)
                    try fileManager.createDirectory(
                        at: stagedURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                    try await fileTransferStrategy.downloadFile(storagePath: file.storagePath, to: stagedURL)
                    return StagedWorkingTreeFile(path: file.path, url: stagedURL)
                }
            }

            var stagedFiles: [StagedWorkingTreeFile] = []
            for try await stagedFile in group {
                if let stagedFile {
                    stagedFiles.append(stagedFile)
                }
            }

            return stagedFiles
        }
    }

    func backupExistingItems(paths: Set<String>, from localRootURL: URL,
                             to backupRootURL: URL) throws -> [WorkingTreeBackup] {
        var backups: [WorkingTreeBackup] = []

        do {
            for path in paths.sorted() {
                let sourceURL = localRootURL.appendingPathComponent(path)
                guard fileManager.fileExists(atPath: sourceURL.path) else { continue }

                let backupURL = backupRootURL.appendingPathComponent(path)
                try fileManager.createDirectory(
                    at: backupURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.moveItem(at: sourceURL, to: backupURL)
                backups.append(WorkingTreeBackup(path: path, url: backupURL))
            }
        } catch let backupError {
            do {
                try restore(backups, to: localRootURL)
            } catch let restoreError {
                throw WorkingTreeError.backupAndRestoreFailed(
                    backupError: backupError,
                    restoreError: restoreError
                )
            }

            throw WorkingTreeError.backupFailed(backupError)
        }

        return backups
    }

    func install(_ stagedFiles: [StagedWorkingTreeFile], in localRootURL: URL,
                 backedUpPaths: Set<String>) throws {
        var installedPaths: [String] = []

        for stagedFile in stagedFiles {
            let destinationURL = localRootURL.appendingPathComponent(stagedFile.path)

            do {
                try fileManager.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.moveItem(at: stagedFile.url, to: destinationURL)
                installedPaths.append(stagedFile.path)
            } catch {
                cleanupInstalledFiles(installedPaths, in: localRootURL, backedUpPaths: backedUpPaths)
                throw error
            }
        }
    }

    func cleanupInstalledFiles(_ paths: [String], in localRootURL: URL,
        backedUpPaths: Set<String>) {
        for path in paths.reversed() where !backedUpPaths.contains(path) {
            let url = localRootURL.appendingPathComponent(path)
            try? fileManager.removeItem(at: url)
        }
    }

    func removeEmptyDirectories(in rootURL: URL) throws {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var directories: [URL] = []
        for case let url as URL in enumerator {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDirectory {
                directories.append(url)
            }
        }

        for url in directories.reversed() {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil
            )
            if contents.isEmpty {
                try fileManager.removeItem(at: url)
            }
        }
    }

    func restore(_ backups: [WorkingTreeBackup], to localRootURL: URL) throws {
        for backup in backups.reversed() {
            let restoredURL = localRootURL.appendingPathComponent(backup.path)
            try fileManager.createDirectory(
                at: restoredURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if fileManager.fileExists(atPath: restoredURL.path) {
                try fileManager.removeItem(at: restoredURL)
            }
            try fileManager.moveItem(at: backup.url, to: restoredURL)
        }
    }
}
