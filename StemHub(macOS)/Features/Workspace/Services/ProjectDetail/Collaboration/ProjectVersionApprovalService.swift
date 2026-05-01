//
//  ProjectVersionApprovalService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol ProjectVersionApprovalServiceProtocol {
    func approveVersion(versionID: String, approvedBy userID: String) async throws
}

final class ProjectVersionApprovalService: ProjectVersionApprovalServiceProtocol {
    private let versionRepository: VersionRepository

    init(versionRepository: VersionRepository) {
        self.versionRepository = versionRepository
    }

    func approveVersion(versionID: String, approvedBy userID: String) async throws {
        try await versionRepository.approveVersion(versionID: versionID, approvedBy: userID)
    }
}
