//
//  ProjectCreationService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import AppKit
import Foundation

protocol ProjectCreationServiceProtocol {
    func createProject(_ input: CreateProjectInput, userID: String, existingProjects: [Project]) async throws -> Project
}

final class ProjectCreationService: ProjectCreationServiceProtocol {
    private let bandRepository: any BandCreating & UserBandLinking
    private let projectRepository: any ProjectCreating & ProjectDuplicateChecking & ProjectPosterUpdating
    private let stateStore: ProjectStateStore
    private let bookmarkStrategy: BookmarkStrategy
    private let posterEncoder: PosterEncoding
    
    init(
        bandRepository: any BandCreating & UserBandLinking,
        projectRepository: any ProjectCreating & ProjectDuplicateChecking & ProjectPosterUpdating,
        stateStore: ProjectStateStore,
        bookmarkStrategy: BookmarkStrategy,
        posterEncoder: PosterEncoding
    ) {
        self.bandRepository = bandRepository
        self.projectRepository = projectRepository
        self.stateStore = stateStore
        self.bookmarkStrategy = bookmarkStrategy
        self.posterEncoder = posterEncoder
    }
    
    func createProject(_ input: CreateProjectInput, userID: String, existingProjects: [Project]) async throws -> Project {
        let trimmedName = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw ProjectCreationServiceError.invalidName }
        
        let band = try await resolveBand(
            projectName: trimmedName,
            selection: input.bandSelection,
            userID: userID,
            existingProjects: existingProjects
        )
        
        let (project, syncState) = try await projectRepository.createProject(
            name: trimmedName,
            bandID: band.id,
            localFolderURL: input.folderURL,
            userID: userID
        )
        
        var state = syncState
        state.localPath = input.folderURL.path
        stateStore.saveSyncState(state)
        
        let bookmark = try bookmarkStrategy.createBookmark(for: input.folderURL)
        stateStore.saveBookmarkData(bookmark, for: project.id)
        
        var updatedProject = project
        if let poster = input.poster {
            let base64 = try posterEncoder.encodeBase64JPEG(from: poster, compression: 0.7)
            try await projectRepository.updatePosterBase64(projectID: project.id, base64: base64)
            updatedProject.posterBase64 = base64
        }
        
        return updatedProject
    }
}

private extension ProjectCreationService {
    
    func resolveBand(
        projectName: String,
        selection: CreateProjectBandSelection,
        userID: String,
        existingProjects: [Project]
    ) async throws -> Band {
        switch selection {
        case let .existing(selectedBand):
            return try await resolveExistingBand(
                selectedBand,
                projectName: projectName,
                existingProjects: existingProjects
            )

        case let .new(name, additionalAdminUserIDs):
            let trimmedBandName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedBandName.isEmpty else {
                throw ProjectCreationServiceError.invalidBandName
            }

            let collaboratorIDs = NSOrderedSet(array: [userID] + additionalAdminUserIDs)
                .array
                .compactMap { $0 as? String }

            let newBand = try await bandRepository.createBand(
                name: trimmedBandName,
                primaryAdminUserID: userID,
                adminUserIDs: collaboratorIDs,
                memberUserIDs: collaboratorIDs
            )

            for memberID in collaboratorIDs {
                try await bandRepository.addBand(to: memberID, bandID: newBand.id)
            }

            return newBand
        }
    }
    
    func resolveExistingBand(
        _ band: Band,
        projectName: String,
        existingProjects: [Project]
    ) async throws -> Band {
        
        let hasLocalDuplicate = existingProjects.contains {
            $0.bandID == band.id &&
            $0.name.caseInsensitiveCompare(projectName) == .orderedSame
        }
        
        if hasLocalDuplicate {  throw ProjectCreationServiceError.duplicateName}
        
        let hasRemoteDuplicate = try await projectRepository.isDuplicateProject(
            name: projectName,
            bandID: band.id
        )
        
        if hasRemoteDuplicate {throw ProjectCreationServiceError.duplicateName}
        
        return band
    }
}
