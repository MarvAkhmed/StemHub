//
//  CommitStorageStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol CommitStorageStrategy {
    func saveCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws -> ProjectVersion
    func fetchCommit(commitID: String) async throws -> Commit?
}
