//
//  BranchWorkspaceState.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 25.04.2026.
//

import Foundation

struct BranchWorkspaceState {
    let branches: [Branch]
    let selectedBranch: Branch
    let versionHistory: [ProjectVersion]
    let headVersionID: String?
}
