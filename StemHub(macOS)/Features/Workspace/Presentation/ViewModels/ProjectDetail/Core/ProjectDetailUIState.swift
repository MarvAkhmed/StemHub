//
//  ProjectDetailUIState.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectDetailUIState {
    var activityState: ProjectDetailActivityState = .idle
    var newBranchName = ""
    var inviteMemberEmail = ""
    var errorMessage: String?
    var showRelocationAlert = false
}
