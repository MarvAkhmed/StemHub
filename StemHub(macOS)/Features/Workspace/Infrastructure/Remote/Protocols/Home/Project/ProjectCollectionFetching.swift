//
//  ProjectCollectionFetching.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectCollectionFetching: Sendable {
    func fetchProjects(for userID: String) async throws -> [Project]
}
