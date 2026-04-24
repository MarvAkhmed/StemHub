//
//  ProjectRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

protocol ProjectCollectionFetching {
    func fetchProjects(for userID: String) async throws -> [Project]
}

protocol ProjectCreating {
    func createProject(name: String, bandID: String, localFolderURL: URL, userID: String) async throws -> (Project, ProjectSyncState)
}

protocol ProjectFetching {
    func fetchProject(projectID: String) async throws -> Project?
}

protocol ProjectDeleting {
    func deleteProject(projectID: String, bandID: String) async throws
}

protocol ProjectDuplicateChecking {
    func isDuplicateProject(name: String, bandID: String) async throws -> Bool
}

protocol ProjectPosterUpdating {
    func updatePosterBase64(projectID: String, base64: String) async throws
}

protocol ProjectWorkspaceStateUpdating {
    func updateWorkspaceState(projectID: String, currentBranchID: String, currentVersionID: String?) async throws
}

protocol ProjectRepository:
    ProjectCollectionFetching,
    ProjectCreating,
    ProjectFetching,
    ProjectDeleting,
    ProjectDuplicateChecking,
    ProjectPosterUpdating,
    ProjectWorkspaceStateUpdating {}
