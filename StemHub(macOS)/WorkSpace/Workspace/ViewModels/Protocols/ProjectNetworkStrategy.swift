//
//  ProjectNetworkStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI
import FirebaseFirestore

protocol ProjectNetworkStrategy {
    // bands
    func createBand(name: String, userID: String) async throws -> Band
    func fetchBands(for userID: String) async throws -> [Band]
    func addBand(to userID: String, bandID: String) async throws
    
    // projects
    func createProject(name: String, bandID: String, localFolderURL: URL, userID: String) async throws -> (Project, LocalProjectState)
    func fetchAllProjects(for userID: String) async throws -> [Project]
    func uploadProjectPoster(projectID: String, image: NSImage) async throws -> String
    func updateProjectPoster(projectID: String, posterURL: String) async throws
    func pullProject(projectID: String, branchID: String, localRootURL: URL, state: LocalProjectState) async throws -> LocalProjectState
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
    func pushCommit(_ commit: Commit, localRootURL: URL, branchID: String) async throws ->  ProjectVersion
    func checkDuplicateProject(name: String, bandID: String) async throws -> Bool
    
    func getFirestore() -> FirebaseFirestore.Firestore
    func fetchProject(projectID: String) async throws -> Project?
}
