//
//  SyncError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

enum SyncError: LocalizedError {
    case branchNotFound, projectNotFound, outdatedCommit
    
    var errorDescription: String? {
        switch self {
        case .branchNotFound:
            return "Branch not found! Please check the branch name."
        case .projectNotFound:
            return "Project not found! Please check the project name."
        case .outdatedCommit:
            return "Outdated commit! Please pull the latest changes."
        }
    }
}
