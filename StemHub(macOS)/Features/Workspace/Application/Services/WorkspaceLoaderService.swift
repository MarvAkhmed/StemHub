//
//  WorkspaceLoaderService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol WorkspaceLoaderServiceProtocol {
    func loadWorkspace(for userID: String) async throws -> WorkspaceSnapshot
}

final class WorkspaceLoaderService: WorkspaceLoaderServiceProtocol {
    private let bandRepository: any UserBandCollectionFetching
    private let projectRepository: any ProjectCollectionFetching

    init(
        bandRepository: any UserBandCollectionFetching,
        projectRepository: any ProjectCollectionFetching
    ) {
        self.bandRepository = bandRepository
        self.projectRepository = projectRepository
    }

    func loadWorkspace(for userID: String) async throws -> WorkspaceSnapshot {
        async let bands = bandRepository.fetchBands(for: userID)
        async let projects = projectRepository.fetchProjects(for: userID)
        return try await WorkspaceSnapshot(bands: bands, projects: projects)
    }
}
