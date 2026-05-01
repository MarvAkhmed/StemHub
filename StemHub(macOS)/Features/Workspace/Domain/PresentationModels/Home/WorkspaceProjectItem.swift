//
//  WorkspaceProjectItem.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct WorkspaceProjectItem: Identifiable, Hashable {
    let project: Project
    let bandName: String
    let diffSummary: ProjectDiffMetadataSummary
    let canDelete: Bool
    let isBandAdmin: Bool

    var id: String { project.id }
    var projectName: String { project.name }

    func matchesSearch(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return project.name.localizedCaseInsensitiveContains(query)
    }
}

