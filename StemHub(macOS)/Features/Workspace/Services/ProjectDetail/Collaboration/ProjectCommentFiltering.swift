//
//  ProjectCommentFiltering.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 25.04.2026.
//

import Foundation

protocol ProjectCommentFiltering {
    func selectedFileComments(
        from versionComments: [Comment],
        selectedFilePath: String?
    ) -> [Comment]
    func visibleTimelineComments(from comments: [Comment]) -> [Comment]
}

struct DefaultProjectCommentFilter: ProjectCommentFiltering {
    func selectedFileComments(
        from versionComments: [Comment],
        selectedFilePath: String?
    ) -> [Comment] {
        guard let selectedFilePath else { return [] }

        return versionComments
            .filter { $0.filePath == selectedFilePath }
            .sorted(by: sortByTimelinePosition)
    }

    func visibleTimelineComments(from comments: [Comment]) -> [Comment] {
        comments.filter { $0.timestamp != nil && $0.isHiddenFromTimeline == false }
    }
}

private extension DefaultProjectCommentFilter {
    func sortByTimelinePosition(_ lhs: Comment, _ rhs: Comment) -> Bool {
        let leftTimestamp = lhs.timestamp ?? -.greatestFiniteMagnitude
        let rightTimestamp = rhs.timestamp ?? -.greatestFiniteMagnitude

        if leftTimestamp == rightTimestamp {
            return lhs.createdAt < rhs.createdAt
        }

        return leftTimestamp < rightTimestamp
    }
}
