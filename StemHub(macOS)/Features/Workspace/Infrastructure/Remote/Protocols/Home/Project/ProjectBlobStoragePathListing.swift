//
//  ProjectBlobStoragePathListing.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

protocol ProjectBlobStoragePathListing: Sendable {
    func fetchBlobStoragePaths(projectID: String, bandID: String) async throws -> [String]
}
