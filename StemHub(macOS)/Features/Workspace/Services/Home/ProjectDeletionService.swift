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
    private let remoteBlobCleaner: any ProjectRemoteBlobCleaning
    private let stateStore: ProjectStateStore
    private let localCommitStore: LocalCommitStore

    init(
        projectRepository: any ProjectDeleting,
        remoteBlobCleaner: any ProjectRemoteBlobCleaning,
        stateStore: ProjectStateStore,
        localCommitStore: LocalCommitStore
    ) {
        self.projectRepository = projectRepository
        self.remoteBlobCleaner = remoteBlobCleaner
        self.stateStore = stateStore
        self.localCommitStore = localCommitStore
    }

    func deleteProject(_ project: Project) async throws {
        let remoteBlobCleanupPlan = try await remoteBlobCleaner.makeCleanupPlan(for: project.id, bandID: project.bandID)
        try await projectRepository.deleteProject(projectID: project.id, bandID: project.bandID)
        stateStore.removePersistence(for: project.id)
        try localCommitStore.removeCache(for: project.id)
        try await remoteBlobCleaner.cleanupBlobs(using: remoteBlobCleanupPlan)
    }
}
