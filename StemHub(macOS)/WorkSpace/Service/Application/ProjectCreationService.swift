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
    private let bandRepository: BandRepository
    private let projectRepository: ProjectRepository
    private let stateStore: ProjectStateStore
    private let bookmarkStrategy: BookmarkStrategy
    private let posterEncoder: PosterEncoding

    init(
        bandRepository: BandRepository = FirestoreBandRepository(),
        projectRepository: ProjectRepository = FirestoreProjectRepository(),
        stateStore: ProjectStateStore = UserDefaultsProjectStateStore(),
        bookmarkStrategy: BookmarkStrategy = DefaultBookmarkStrategy(),
        posterEncoder: PosterEncoding = PosterEncoderService()
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
            selectedBand: input.selectedBand,
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

    private func resolveBand(
        projectName: String,
        selectedBand: Band?,
        userID: String,
        existingProjects: [Project]
    ) async throws -> Band {
        if let selectedBand {
            if existingProjects.contains(where: {
                $0.bandID == selectedBand.id && $0.name.caseInsensitiveCompare(projectName) == .orderedSame
            }) {
                throw ProjectCreationServiceError.duplicateName
            }

            if try await projectRepository.isDuplicateProject(name: projectName, bandID: selectedBand.id) {
                throw ProjectCreationServiceError.duplicateName
            }

            return selectedBand
        }

        let newBand = try await bandRepository.createBand(name: "\(projectName) Band", userID: userID)
        try await bandRepository.addBand(to: userID, bandID: newBand.id)
        return newBand
    }
}
