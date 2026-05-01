//
//  ProjectStateKeyBuilder.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct ProjectStateKeyBuilder {
    nonisolated func stateKey(for projectID: String) -> String {
        "project_\(projectID)_syncState"
    }

    nonisolated func bookmarkKey(for projectID: String) -> String {
        "project_\(projectID)_bookmark"
    }
}
