//
//  IOSReleaseCandidate.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct IOSReleaseCandidate: Identifiable, Hashable, Sendable {
    let id: String
    let projectName: String
    let bandName: String
    let latestVersionLabel: String
    let latestActivity: Date
    let isBandAdmin: Bool
    let artworkBase64: String?
}
