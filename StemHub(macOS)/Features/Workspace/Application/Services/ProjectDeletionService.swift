//
//  ProjectDeletionService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol ProjectDeletionServiceProtocol {
    func deleteProject(_ project: Project) async throws
}

final class ProjectDeletionService: ProjectDeletionServiceProtocol {
    private let projectRepository: any ProjectDeleting
    private let stateStore: ProjectStateStore
    private let localCommitStore: LocalCommitStore

    init(
        projectRepository: any ProjectDeleting,
        stateStore: ProjectStateStore,
        localCommitStore: LocalCommitStore
    ) {
        self.projectRepository = projectRepository
        self.stateStore = stateStore
        self.localCommitStore = localCommitStore
    }

    func deleteProject(_ project: Project) async throws {
        try await projectRepository.deleteProject(projectID: project.id, bandID: project.bandID)
        stateStore.removePersistence(for: project.id)
        localCommitStore.removeCache(for: project.id)
    }
}
