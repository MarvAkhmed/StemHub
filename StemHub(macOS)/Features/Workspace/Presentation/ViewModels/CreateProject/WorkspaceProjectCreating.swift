//
//  WorkspaceProjectCreating.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

@MainActor
protocol WorkspaceProjectCreating: AnyObject {
    var bands: [Band] { get }
    var errorMessage: String? { get }

    func createProject(_ input: CreateProjectInput) async
    func clearError()
}
