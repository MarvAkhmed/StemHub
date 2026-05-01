//
//  CreateProjectInput.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import AppKit

enum CreateProjectBandSelection {
    case existing(Band)
    case new(name: String, additionalAdminUserIDs: [String])
}

struct CreateProjectInput {
    let name: String
    let folderURL: URL
    let bandSelection: CreateProjectBandSelection
    let poster: NSImage?
}
