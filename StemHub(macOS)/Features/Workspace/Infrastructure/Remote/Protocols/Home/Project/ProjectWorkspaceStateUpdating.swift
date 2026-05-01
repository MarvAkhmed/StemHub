//
//  ProjectWorkspaceStateUpdating.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectWorkspaceStateUpdating: Sendable {
    func updateWorkspaceState(projectID: String, currentBranchID: String, currentVersionID: String?) async throws
}
