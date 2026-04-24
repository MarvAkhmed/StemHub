//
//  WorkspaceProjectCatalogService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol WorkspaceProjectCatalogProviding {
    func loadCatalog(for userID: String) async throws -> WorkspaceProjectCatalog
}

final class WorkspaceProjectCatalogService: WorkspaceProjectCatalogProviding {
    private let workspaceLoader: WorkspaceLoaderServiceProtocol
    private let versionService: ProjectVersionService

    init(
        workspaceLoader: WorkspaceLoaderServiceProtocol,
        versionService: ProjectVersionService
    ) {
        self.workspaceLoader = workspaceLoader
        self.versionService = versionService
    }

    func loadCatalog(for userID: String) async throws -> WorkspaceProjectCatalog {
        let snapshot = try await workspaceLoader.loadWorkspace(for: userID)
        let versionsByID = try await currentVersions(for: snapshot.projects)
        let sections = buildSections(
            from: snapshot,
            currentUserID: userID,
            versionsByID: versionsByID
        )

        return WorkspaceProjectCatalog(snapshot: snapshot, sections: sections)
    }
}

private extension WorkspaceProjectCatalogService {
    func currentVersions(for projects: [Project]) async throws -> [String: ProjectVersion] {
        let versionIDs = projects
            .map(\.currentVersionID)
            .filter { !$0.isEmpty }

        guard !versionIDs.isEmpty else { return [:] }

        let versions = try await versionService.fetchVersions(versionIDs: versionIDs)
        return Dictionary(uniqueKeysWithValues: versions.map { ($0.id, $0) })
    }

    func buildSections(
        from snapshot: WorkspaceSnapshot,
        currentUserID: String,
        versionsByID: [String: ProjectVersion]
    ) -> [WorkspaceBandSection] {
        let bandsByID = Dictionary(uniqueKeysWithValues: snapshot.bands.map { ($0.id, $0) })
        let projectItems = snapshot.projects.map { project in
            let band = bandsByID[project.bandID]
            let currentVersion = versionsByID[project.currentVersionID]
            let isBandAdmin = band?.isAdmin(userID: currentUserID) ?? false

            return WorkspaceProjectItem(
                project: project,
                bandName: band?.name ?? "Other Collaborations",
                diffSummary: ProjectDiffMetadataSummary(projectVersion: currentVersion),
                canDelete: isBandAdmin || project.createdBy == currentUserID,
                isBandAdmin: isBandAdmin
            )
        }

        let groupedItems = Dictionary(grouping: projectItems, by: \.project.bandID)
        var sections: [WorkspaceBandSection] = []

        for band in snapshot.bands.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) {
            guard let items = groupedItems[band.id], !items.isEmpty else { continue }
            let sortedItems = items.sorted { $0.project.updatedAt > $1.project.updatedAt }
            sections.append(
                WorkspaceBandSection(
                    id: band.id,
                    title: band.name,
                    subtitle: "\(sortedItems.count) project\(sortedItems.count == 1 ? "" : "s")",
                    projects: sortedItems
                )
            )
        }

        let orphanProjects = projectItems
            .filter { bandsByID[$0.project.bandID] == nil }
            .sorted { $0.project.updatedAt > $1.project.updatedAt }

        if !orphanProjects.isEmpty {
            sections.append(
                WorkspaceBandSection(
                    id: "other-collaborations",
                    title: "Other Collaborations",
                    subtitle: "\(orphanProjects.count) project\(orphanProjects.count == 1 ? "" : "s")",
                    projects: orphanProjects
                )
            )
        }

        return sections
    }
}

