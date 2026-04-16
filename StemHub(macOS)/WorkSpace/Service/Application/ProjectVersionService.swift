//
//  ProjectVersionService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectVersionService {
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion]
    func fetchVersion(versionID: String) async throws -> ProjectVersion?
    func fetchFiles(for version: ProjectVersion) async throws -> [MusicFile]
}

final class DefaultProjectVersionService: ProjectVersionService {
    private let versionRepository: VersionRepository

    init(versionRepository: VersionRepository = DefaultVersionRepository()) {
        self.versionRepository = versionRepository
    }

    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        try await versionRepository.fetchVersionHistory(projectID: projectID)
    }

    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        try await versionRepository.fetchVersion(versionID: versionID)
    }

    func fetchFiles(for version: ProjectVersion) async throws -> [MusicFile] {
        let fileVersions = try await versionRepository.fetchFileVersions(fileVersionIDs: version.fileVersionIDs)

        return fileVersions.map { fileVersion in
            MusicFile(
                id: fileVersion.fileID,
                projectID: version.projectID,
                name: (fileVersion.path as NSString).lastPathComponent,
                fileExtension: (fileVersion.path as NSString).pathExtension,
                path: fileVersion.path,
                capabilities: .playable,
                currentVersionID: fileVersion.id,
                availableFormats: [],
                createdAt: fileVersion.createdAt
            )
        }
    }
}
