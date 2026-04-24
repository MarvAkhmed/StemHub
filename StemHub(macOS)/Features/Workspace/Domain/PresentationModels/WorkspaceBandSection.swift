//
//  WorkspaceBandSection.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct WorkspaceBandSection: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let projects: [WorkspaceProjectItem]
}

