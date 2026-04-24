//
//  CommitRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

protocol CommitRepository {
    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion
}
