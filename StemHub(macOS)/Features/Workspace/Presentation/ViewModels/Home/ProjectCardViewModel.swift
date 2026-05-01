//
//  ProjectCardViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import AppKit
import Foundation
import SwiftUI

struct ProjectCardViewModel {
    struct ChangeMetric: Identifiable {
        let id: String
        let title: String
        let count: Int
        let systemImage: String
        let tint: Color
    }

    let item: WorkspaceProjectItem
    private let posterImageProvider: ProjectPosterImageProviding
    
    init(item: WorkspaceProjectItem, posterImageProvider: ProjectPosterImageProviding) {
        self.item = item
        self.posterImageProvider = posterImageProvider
    }

    var project: Project { item.project }
    var name: String { item.project.name }
   
    
    var projectPosterImage: NSImage? {
        posterImageProvider.image(from: item.project.posterBase64)
    }

    var updatedAtFormatted: String {
        Self.dateFormatter.string(from: item.project.updatedAt)
    }

    var versionBadgeTitle: String {
        item.diffSummary.latestVersionNumber.map { "v\($0)" } ?? "Draft"
    }

    var versionTitle: String {
        item.diffSummary.versionTitle
    }

    var approvalTitle: String {
        item.diffSummary.approvalTitle
    }

    var approvalColor: Color {
        switch item.diffSummary.approvalState {
        case .approved:
            return Color.green
        case .pendingReview:
            return Color.orange
        case nil:
            return Color.secondary
        }
    }

    var metadataDescription: String {
        if item.diffSummary.hasSavedVersion {
            let total = item.diffSummary.totalChangeCount
            return total == 0
                ? "Latest saved version has no tracked file changes."
                : "\(total) tracked change\(total == 1 ? "" : "s") in the latest saved version."
        }

        return "Save the first version to see change metadata here."
    }

    var changeMetrics: [ChangeMetric] {
        [
            ChangeMetric(id: "added", title: "Added", count: item.diffSummary.addedCount, systemImage: "plus", tint: .green),
            ChangeMetric(id: "changed", title: "Changed", count: item.diffSummary.modifiedCount, systemImage: "slider.horizontal.3", tint: .orange),
            ChangeMetric(id: "removed", title: "Removed", count: item.diffSummary.removedCount, systemImage: "minus", tint: .red),
            ChangeMetric(id: "renamed", title: "Renamed", count: item.diffSummary.renamedCount, systemImage: "arrow.left.arrow.right", tint: .blue)
        ]
        .filter { $0.count > 0 }
    }

    var canDelete: Bool {
        item.canDelete
    }

    var collaboratorBadgeTitle: String {
        item.isBandAdmin ? "Admin" : "Collaborator"
    }
}

private extension ProjectCardViewModel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
