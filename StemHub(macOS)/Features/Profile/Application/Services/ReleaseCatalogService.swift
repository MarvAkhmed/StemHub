//
//  ReleaseCatalogService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol ReleaseCatalogProviding {
    func fetchReleaseCandidates(for userID: String) async throws -> [ReleaseCandidate]
}

final class ReleaseCatalogService: ReleaseCatalogProviding {
    private let workspaceLoader: WorkspaceLoaderServiceProtocol
    private let versionRepository: VersionRepository

    init(
        workspaceLoader: WorkspaceLoaderServiceProtocol,
        versionRepository: VersionRepository
    ) {
        self.workspaceLoader = workspaceLoader
        self.versionRepository = versionRepository
    }

    func fetchReleaseCandidates(for userID: String) async throws -> [ReleaseCandidate] {
        let snapshot = try await workspaceLoader.loadWorkspace(for: userID)
        let bandLookup = Dictionary(uniqueKeysWithValues: snapshot.bands.map { ($0.id, $0) })

        return try await withThrowingTaskGroup(of: ReleaseCandidate?.self) { group in
            for project in snapshot.projects {
                group.addTask { [versionRepository] in
                    let versions = try await versionRepository.fetchVersionHistory(projectID: project.id)
                    guard let latestVersion = versions.first(where: { $0.approvalState == .approved }) else { return nil }
                    let band = bandLookup[project.bandID]
                    return ReleaseCandidate(
                        id: project.id,
                        projectName: project.name,
                        bandName: band?.name ?? "Independent",
                        latestVersionLabel: "Version \(latestVersion.versionNumber)",
                        latestActivity: latestVersion.createdAt,
                        isBandAdmin: band?.adminUserID == userID,
                        artworkBase64: project.posterBase64
                    )
                }
            }

            var candidates: [ReleaseCandidate] = []
            for try await candidate in group {
                if let candidate {
                    candidates.append(candidate)
                }
            }

            return candidates.sorted { $0.latestActivity > $1.latestActivity }
        }
    }
}
