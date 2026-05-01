//
//  ProjectCreationPersisting.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectCreationPersisting: ProjectPosterUpdating, Sendable {
    func createProject(_ project: Project, initialBranch: Branch) async throws
    func isDuplicateProject(name: String, bandID: String) async throws -> Bool
}
