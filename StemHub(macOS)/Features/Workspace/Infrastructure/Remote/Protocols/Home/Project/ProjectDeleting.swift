//
//  ProjectDeleting.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectDeleting: Sendable {
    func deleteProject(projectID: String, bandID: String) async throws
}
