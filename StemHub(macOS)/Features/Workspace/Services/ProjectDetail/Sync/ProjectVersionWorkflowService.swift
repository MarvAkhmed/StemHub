//
//  ProjectVersionWorkflowService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectVersionSelection {
    let version: ProjectVersion
    let diff: ProjectDiff?
}

protocol ProjectVersionWorkflowing {
    func loadVersionDetails(
        versionID: String,
        versionHistory: [ProjectVersion]
    ) async throws -> ProjectVersionSelection

    func approveVersion(versionID: String, approvedBy userID: String) async throws
}

final class ProjectVersionWorkflowService: ProjectVersionWorkflowing {
    private let versionService: ProjectVersionService
    private let versionApprovalService: ProjectVersionApprovalServiceProtocol

    init(
        versionService: ProjectVersionService,
        versionApprovalService: ProjectVersionApprovalServiceProtocol
    ) {
        self.versionService = versionService
        self.versionApprovalService = versionApprovalService
    }

    func loadVersionDetails(versionID: String,
                            versionHistory: [ProjectVersion]) async throws -> ProjectVersionSelection {
        let fetchedVersion = try await versionService.fetchVersion(versionID: versionID)

        guard let version = versionHistory.first(where: { $0.id == versionID }) ?? fetchedVersion
        else { throw ProjectDetailError.missingVersionContext }

        return ProjectVersionSelection(version: version,
                                       diff: version.diff)
    }

    func approveVersion(versionID: String, approvedBy userID: String) async throws {
        try await versionApprovalService.approveVersion(versionID: versionID,
                                                        approvedBy: userID)
    }
}
