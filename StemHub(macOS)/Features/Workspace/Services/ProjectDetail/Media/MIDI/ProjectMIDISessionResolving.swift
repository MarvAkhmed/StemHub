//
//  ProjectMIDISessionResolving.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol ProjectMIDISessionResolving {
    func resolveSession(
        project: Project,
        selectedFileURL: URL?,
        currentBranchName: String,
        currentVersionTitle: String
    ) async throws -> ProjectMIDISession
}

final class DefaultProjectMIDISessionResolver: ProjectMIDISessionResolving {
    private let folderService: any ProjectMIDIFolderAccessing
    private let fileTypeProvider: ProjectFileTypeProviding
    private let workQueue = DispatchQueue(label: "com.stemhub.project-midi-session",
                                          qos: .userInitiated)
    
    init(
        folderService: any ProjectMIDIFolderAccessing,
        fileTypeProvider: ProjectFileTypeProviding
    ) {
        self.folderService = folderService
        self.fileTypeProvider = fileTypeProvider
    }
    
    func resolveSession(
        project: Project,
        selectedFileURL: URL?,
        currentBranchName: String,
        currentVersionTitle: String
    ) async throws -> ProjectMIDISession {
        try await withCheckedThrowingContinuation { continuation in
            workQueue.async { [folderService, fileTypeProvider] in
                do {
                    let rootURL = try self.resolveRootURL(
                        for: project,
                        folderService: folderService
                    )
                    let preferredURL = self.resolvePreferredMIDIURL(
                        projectID: project.id,
                        rootURL: rootURL,
                        selectedFileURL: selectedFileURL,
                        projectName: project.name,
                        folderService: folderService,
                        fileTypeProvider: fileTypeProvider
                    )
                    let relativePath = folderService.relativePath(
                        for: preferredURL,
                        projectID: project.id
                    ) ?? preferredURL.lastPathComponent
                    
                    continuation.resume(
                        returning: ProjectMIDISession(
                            projectID: project.id,
                            projectName: project.name,
                            branchName: currentBranchName,
                            versionTitle: currentVersionTitle,
                            fileURL: preferredURL,
                            relativePath: relativePath,
                            fileExists: FileManager.default.fileExists(atPath: preferredURL.path)
                        )
                    )
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func resolveRootURL(
        for project: Project,
        folderService: any ProjectMIDIFolderAccessing
    ) throws -> URL {
        guard let rootURL = folderService.resolveFolderURL(for: project.id) else {
            throw ProjectDetailError.missingProjectFolder
        }
        
        return rootURL
    }
    
    private func resolvePreferredMIDIURL(projectID: String,
                                         rootURL: URL,
                                         selectedFileURL: URL?,
                                         projectName: String,
                                         folderService: any ProjectMIDIFolderAccessing,
                                         fileTypeProvider: ProjectFileTypeProviding) -> URL {
        if let selectedFileURL,
           fileTypeProvider.isMIDIFile(url: selectedFileURL),
           folderService.relativePath(for: selectedFileURL, projectID: projectID) != nil {
            return selectedFileURL
        }
        
        let existingMIDIURLs = flattenMIDIURLs(
            nodes: folderService.fileTree(for: projectID),
            fileTypeProvider: fileTypeProvider
        )
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        
        if let existingMIDIURL = existingMIDIURLs.first {
            return existingMIDIURL
        }
        
        return rootURL.appendingPathComponent("\(sanitizeFileStem(projectName)) Arrangement.mid")
    }
    
    private func flattenMIDIURLs(nodes: [FileTreeNode],
                                 fileTypeProvider: ProjectFileTypeProviding) -> [URL] {
        
        nodes.flatMap { node -> [URL] in
            if let children = node.children, node.isDirectory {
                return flattenMIDIURLs(
                    nodes: children,
                    fileTypeProvider: fileTypeProvider
                )
            }
            
            guard !node.isDirectory, fileTypeProvider.isMIDIFile(url: node.url) else {
                return []
            }
            
            return [node.url]
        }
    }
    
    private func sanitizeFileStem(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
        let components = value.components(separatedBy: invalidCharacters)
        let joined = components.joined(separator: " ")
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Project" : trimmed
    }
}
