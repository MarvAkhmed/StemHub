//
//  ProjectDetailWorkspaceState.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectDetailWorkspaceState {
    var branches: [Branch] = []
    var currentBranch: Branch?
    var versionHistory: [ProjectVersion] = []
    var selectedVersion: ProjectVersion?
    var versionDiff: ProjectDiff?
    var fileTree: [FileTreeNode] = []
    var localCommits: [LocalCommit] = []
}
