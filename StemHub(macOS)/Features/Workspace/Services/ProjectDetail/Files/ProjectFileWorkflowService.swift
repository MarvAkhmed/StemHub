//
//  ProjectFileWorkflowService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectFileSelectionResult {
    let url: URL?
    let path: String?
}

struct ProjectFileImportResult {
    let importedURLs: [URL]
    let fileTree: [FileTreeNode]
}

protocol ProjectFileWorkflowing {
    func selectFile(_ url: URL?, projectID: String) async -> ProjectFileSelectionResult
    func restoreSelection(relativePath: String?, projectID: String) async -> ProjectFileSelectionResult
    func importAudioFiles(_ fileURLs: [URL], projectID: String) async throws -> ProjectFileImportResult
    func updateFolderReference(projectID: String, folderURL: URL) async throws
    func relocateProjectFolder(projectID: String, destinationParentURL: URL) async throws
}

final class ProjectFileWorkflowService: ProjectFileWorkflowing {
    private let localWorkspace: ProjectLocalWorkspaceService

    init(localWorkspace: ProjectLocalWorkspaceService) {
        self.localWorkspace = localWorkspace
    }

    func selectFile(_ url: URL?, projectID: String) async -> ProjectFileSelectionResult {
        guard let url else {
            return ProjectFileSelectionResult(url: nil, path: nil)
        }

        return ProjectFileSelectionResult(
            url: url,
            path: await localWorkspace.relativePath(for: url, projectID: projectID)
        )
    }

    func restoreSelection(
        relativePath: String?,
        projectID: String
    ) async -> ProjectFileSelectionResult {
        guard let relativePath else {
            return ProjectFileSelectionResult(url: nil, path: nil)
        }

        guard let url = await localWorkspace.existingFileURL(
            relativePath: relativePath,
            projectID: projectID
        ) else {
            return ProjectFileSelectionResult(url: nil, path: nil)
        }

        return ProjectFileSelectionResult(url: url, path: relativePath)
    }

    func importAudioFiles(
        _ fileURLs: [URL],
        projectID: String
    ) async throws -> ProjectFileImportResult {
        let importedURLs = try await localWorkspace.importAudioFiles(fileURLs, projectID: projectID)
        let fileTree = await localWorkspace.loadFileTree(projectID: projectID)

        return ProjectFileImportResult(
            importedURLs: importedURLs,
            fileTree: fileTree
        )
    }

    func updateFolderReference(projectID: String, folderURL: URL) async throws {
        try await localWorkspace.updateFolderReference(projectID: projectID, folderURL: folderURL)
    }

    func relocateProjectFolder(projectID: String, destinationParentURL: URL) async throws {
        _ = try await localWorkspace.relocateProjectFolder(
            projectID: projectID,
            destinationParentURL: destinationParentURL
        )
    }
}
