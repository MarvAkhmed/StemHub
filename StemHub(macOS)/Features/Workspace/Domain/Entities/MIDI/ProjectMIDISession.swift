//
//  ProjectMIDISession.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

struct ProjectMIDISession: Identifiable, Equatable, Hashable, Sendable {
    let projectID: String
    let projectName: String
    let branchName: String
    let versionTitle: String
    let fileURL: URL
    let relativePath: String
    let fileExists: Bool

    nonisolated var id: String {
        "\(projectID)::\(relativePath)"
    }

    nonisolated var displayTitle: String {
        (relativePath as NSString).lastPathComponent
    }

    nonisolated var contextCaption: String {
        "\(branchName) • \(versionTitle)"
    }
}
