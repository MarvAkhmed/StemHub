//
//  ProjectSyncServiceError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

enum ProjectSyncServiceError: LocalizedError {
    case missingLocalPath
    case missingBranch
    case remoteHasNewCommits

    var errorDescription: String? {
        switch self {
        case .missingLocalPath:
            return "Project folder is missing."
        case .missingBranch:
            return "No branch selected."
        case .remoteHasNewCommits:
            return "Remote has new commits. Pull latest before committing."
        }
    }
}
