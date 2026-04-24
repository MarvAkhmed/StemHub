//
//  ProjectDiffMetadataSummary.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct ProjectDiffMetadataSummary: Hashable, Sendable {
    let latestVersionNumber: Int?
    let approvalState: ProjectVersionApprovalState?
    let addedCount: Int
    let modifiedCount: Int
    let removedCount: Int
    let renamedCount: Int

    init(projectVersion: ProjectVersion?) {
        latestVersionNumber = projectVersion?.versionNumber
        approvalState = projectVersion?.approvalState
        addedCount = projectVersion?.diff.added.count ?? 0
        modifiedCount = projectVersion?.diff.modified.count ?? 0
        removedCount = projectVersion?.diff.removed.count ?? 0
        renamedCount = projectVersion?.diff.renamed.count ?? 0
    }

    var totalChangeCount: Int {
        addedCount + modifiedCount + removedCount + renamedCount
    }

    var hasSavedVersion: Bool {
        latestVersionNumber != nil
    }

    var versionTitle: String {
        guard let latestVersionNumber else {
            return "No Saved Version"
        }

        return "Version \(latestVersionNumber)"
    }

    var approvalTitle: String {
        approvalState?.title ?? "Working Copy Only"
    }
}

