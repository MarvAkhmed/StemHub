//
//  CreateProjectBandSelection.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum CreateProjectBandSelection {
    case existing(Band)
    case new(name: String, additionalAdminUserIDs: [String])
}
