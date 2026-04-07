//
//  ProjectVersionService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

protocol ProjectVersionService {
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion]
    func fetchVersion(versionID: String) async throws -> ProjectVersion?
    func fetchFiles(for version: ProjectVersion) async throws -> [MusicFile]
}

final class DefaultProjectVersionService: ProjectVersionService {
    private let network: ProjectNetworkStrategy
    private let firestoreVersionStrategy: FirestoreVersionStrategy
    
    init(network: ProjectNetworkStrategy = DefaultProjectNetworkStrategy(),
         firestoreVersionStrategy: FirestoreVersionStrategy = DefaultFirestoreVersionStrategy()) {
        self.network = network
        self.firestoreVersionStrategy = firestoreVersionStrategy
    }
    
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        try await firestoreVersionStrategy.fetchVersionHistory(projectID: projectID)
    }
    
    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        try await firestoreVersionStrategy.fetchVersion(versionID: versionID)
    }
    
    func fetchFiles(for version: ProjectVersion) async throws -> [MusicFile] {
        let fileVersions = try await firestoreVersionStrategy.fetchFileVersions(fileVersionIDs: version.fileVersionIDs)
        return fileVersions.map { fv in
            MusicFile(
                id: fv.fileID,
                projectID: version.projectID,
                name: (fv.path as NSString).lastPathComponent,
                fileExtension: (fv.path as NSString).pathExtension,
                path: fv.path,
                capabilities: .playable,
                currentVersionID: fv.id,
                availableFormats: [],
                createdAt: fv.createdAt
            )
        }
    }
}
