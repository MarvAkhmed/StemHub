//
//  VersionRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

protocol VersionRepository {
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion]
    func fetchVersion(versionID: String) async throws -> ProjectVersion?
    func fetchVersions(versionIDs: [String]) async throws -> [ProjectVersion]
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion]
    func approveVersion(versionID: String, approvedBy userID: String) async throws
}
