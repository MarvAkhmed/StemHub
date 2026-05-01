//
//  ProjectPosterUpdating.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol ProjectPosterUpdating: Sendable {
    func updatePosterBase64(projectID: String, base64: String) async throws
}
