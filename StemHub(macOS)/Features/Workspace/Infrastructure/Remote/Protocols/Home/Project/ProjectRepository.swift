//
//  ProjectRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol RemoteProjectRepository:
    ProjectCollectionFetching,
    ProjectCreationPersisting,
    ProjectDeleting,
    ProjectBlobStoragePathListing,
    ProjectWorkspaceStateUpdating {}

protocol ProjectRepository: RemoteProjectRepository {}
