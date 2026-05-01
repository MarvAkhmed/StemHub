//
//  WorkspaceSectionFiltering.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 25.04.2026.
//

import Foundation

protocol WorkspaceSectionFiltering {
    func visibleSections(from sections: [WorkspaceBandSection], query: String) -> [WorkspaceBandSection]
    func projectCountLabel(for count: Int) -> String
    func bandCountLabel(for count: Int) -> String
}

struct DefaultWorkspaceSectionFilter: WorkspaceSectionFiltering {
    func visibleSections(from sections: [WorkspaceBandSection], query: String) -> [WorkspaceBandSection] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return sections }

        return sections.compactMap { section in
            let filteredProjects = section.projects.filter { $0.matchesSearch(trimmedQuery) }
            guard !filteredProjects.isEmpty else { return nil }

            return WorkspaceBandSection(
                id: section.id,
                title: section.title,
                subtitle: projectCountLabel(for: filteredProjects.count),
                projects: filteredProjects
            )
        }
    }

    func projectCountLabel(for count: Int) -> String {
        countLabel(for: count, singular: "project")
    }

    func bandCountLabel(for count: Int) -> String {
        countLabel(for: count, singular: "band")
    }
}

private extension DefaultWorkspaceSectionFilter {
    func countLabel(for count: Int, singular: String) -> String {
        "\(count) \(singular)\(count == 1 ? "" : "s")"
    }
}
