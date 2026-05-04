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
    
    private let bandRepository: any BandCreationPersisting
    private let projectRepository: any ProjectCreationPersisting
    private let stateStore: ProjectStateStore
    private let bookmarkStrategy: BookmarkStrategy
    private let posterEncoder: PosterEncoding
    
    init(
        bandRepository: any BandCreationPersisting,
        projectRepository: any ProjectCreationPersisting,
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
        let trimmedName = try trimmedNonEmpty(input.name, emptyError: .invalidName)
        
        let band = try await resolveBand(projectName: trimmedName,
                                         selection: input.bandSelection,
                                         userID: userID,
                                         existingProjects: existingProjects)
        
        
        let project = makeProjectWithInitialBranch(name: trimmedName, bandID: band.id, userID: userID)
        try await projectRepository.createProject(project.project, initialBranch: project.branch)
        let state = ProjectSyncState(projectID: project.project.id, localPath: input.folderURL.path)
        stateStore.saveSyncState(state)
        
        let bookmark = try bookmarkStrategy.createBookmark(for: input.folderURL)
        stateStore.saveBookmarkData(bookmark, for: project.project.id)
        
        var updatedProject = project
        if let poster = input.poster {
            let base64 = try posterEncoder.encodeBase64JPEG(from: poster, compression: 0.7)
            try await projectRepository.updatePosterBase64(projectID: project.project.id, base64: base64)
            updatedProject.project.posterBase64 = base64
        }
        
        return updatedProject.project
    }
}

private extension ProjectCreationService {
    
    func trimmedNonEmpty(_ value: String, emptyError: ProjectCreationServiceError ) throws -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { throw emptyError }
        return trimmedValue
    }
    
    func makeProjectWithInitialBranch(name: String, bandID: String, userID: String) -> (project: Project, branch: Branch) {
        let branchID = UUID().uuidString
        let projectID = UUID().uuidString
        
        let project = Project(id: projectID, name: name, bandID: bandID,
                              createdBy: userID, currentBranchID: branchID, currentVersionID: "",
                              createdAt: Date(), updatedAt: Date())
        
        let branch = Branch(id: branchID, projectID: projectID, name: "main",
                            headVersionID: nil, createdAt: Date(), createdBy: userID)
        
        
        return (project, branch)
    }
    
    func resolveBand(projectName: String, selection: CreateProjectBandSelection,
                     userID: String, existingProjects: [Project]) async throws -> Band {
        switch selection {
        case let .existing(selectedBand):
            return try await resolveExistingBand(selectedBand,
                                                 projectName: projectName,
                                                 existingProjects: existingProjects)
            
            
        case let .new(name, additionalAdminUserIDs):
            return try await createNewBand(name: name,
                                           primaryAdminUserID: userID,
                                           additionalAdminUserIDs: additionalAdminUserIDs)
        }
    }
    func resolveExistingBand(_ band: Band, projectName: String, existingProjects: [Project]) async throws -> Band {
        try await validateExistingBandLocally(band, projectName: projectName, existingProjects: existingProjects)
        try await validateExistingBandRemotely(band, projectName: projectName)
        return band
    }
    
    
    func createNewBand(name: String, primaryAdminUserID: String, additionalAdminUserIDs: [String]) async throws -> Band {
        let trimmedBandName = try trimmedNonEmpty(name, emptyError: .invalidBandName)
        
        let adminUserIDs = resolvedAdminUserIDs(primaryAdminUserID: primaryAdminUserID,
                                                adminUserIDs: additionalAdminUserIDs)
        
        let memberUserIDs = resolvedMemberUserIDs(primaryAdminUserID: primaryAdminUserID,
                                                  memberUserIDs: additionalAdminUserIDs,
                                                  adminUserIDs: adminUserIDs)
        
        let newBand = makeBand(name: trimmedBandName,
                               primaryAdminUserID: primaryAdminUserID,
                               adminUserIDs: adminUserIDs,
                               memberUserIDs: memberUserIDs)
        
        return newBand
    }
    
    func makeBand(name: String,primaryAdminUserID: String,adminUserIDs: [String], memberUserIDs: [String]) -> Band {
        let band = Band(id: UUID().uuidString, name: name, adminUserID: primaryAdminUserID,
                        adminUserIDs: adminUserIDs, memberIDs: memberUserIDs, projectIDs: [], createdAt: Date())
        return band
    }
    
    func validateExistingBandLocally(_ band: Band,  projectName: String, existingProjects: [Project]) async throws {
        let hasLocalDuplicate = existingProjects.contains {
            $0.bandID == band.id &&
            $0.name.caseInsensitiveCompare(projectName) == .orderedSame
        }
        if hasLocalDuplicate {  throw ProjectCreationServiceError.duplicateName }
    }
    
    func validateExistingBandRemotely(_ band: Band,  projectName: String) async throws  {
        let hasRemoteDuplicate = try await projectRepository.isDuplicateProject(name: projectName,
                                                                                bandID: band.id)
        if hasRemoteDuplicate { throw ProjectCreationServiceError.duplicateName }
        
    }
    
    func resolvedAdminUserIDs(primaryAdminUserID: String, adminUserIDs: [String]) -> [String] {
        orderedUniqueUserIDs([primaryAdminUserID] + adminUserIDs)
    }
    
    func resolvedMemberUserIDs(primaryAdminUserID: String, memberUserIDs: [String],
                               adminUserIDs: [String]) -> [String] {
        orderedUniqueUserIDs([primaryAdminUserID] + memberUserIDs + adminUserIDs)
    }
    
    func orderedUniqueUserIDs(_ userIDs: [String]) -> [String] {
        var seen = Set<String>()
        return userIDs.filter { seen.insert($0).inserted }
    }
}
