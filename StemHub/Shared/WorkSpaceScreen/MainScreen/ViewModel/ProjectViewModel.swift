//
//  ProjectViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
final class ProjectViewModel: ObservableObject {
    
    @Published var project: Project
    @Published var branch: Branch?
    @Published var musicFiles: [MusicFile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let firestore = FirestoreManager.shared
    private let syncOrchestrator = SyncOrchestrator()
    private let scanner = LocalFileScanner()
    private var localState: LocalProjectState
    private var currentUserID: String?

    init(project: Project, localState: LocalProjectState, currentUserID: String?) {
        self.project = project
        self.localState = localState
        self.currentUserID = currentUserID
    }
    
    func loadCurrentBranch() async {
        guard let branchID = localState.currentBranchID else { return }
        isLoading = true
        do {
            let branchDoc = try await firestore.firestore().collection("branches")
                .document(branchID)
                .getDocument()
            self.branch = try branchDoc.data(as: Branch.self)
        } catch {
            errorMessage = "Failed to load branch: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func pullLatest() async {
        guard let branchID = localState.currentBranchID else { return }
        isLoading = true
        do {
            localState = try await firestore.pullProject(
                projectID: project.id,
                branchID: branchID,
                localRootURL: URL(fileURLWithPath: localState.localPath),
                state: localState
            )
            await loadFiles()
        } catch {
            errorMessage = "Pull failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func commitChanges(message: String) async {
        guard let currentUserID = currentUserID else { return }
        isLoading = true
        do {
            let localFiles = try scanner.scan(folderURL: URL(fileURLWithPath: localState.localPath))
            print("local files: \(localFiles)")
            
            var remoteSnapshot: [RemoteFileSnapshot] = []
            if let lastPulledID = localState.lastPulledVersionID {
                remoteSnapshot = try await firestore.fetchRemoteSnapshot(versionID: lastPulledID)
            }
            
            let commit = try await syncOrchestrator.commit(
                localPath: URL(fileURLWithPath: localState.localPath),
                localState: localState,
                remoteSnapshot: remoteSnapshot,
                userID: currentUserID,
                message: message
            )
            
            if let branchID = localState.currentBranchID {
                let _ = try await firestore.pushCommit(
                    commit,
                    localRootURL: URL(fileURLWithPath: localState.localPath),
                    branchID: branchID
                )
                localState.lastCommittedID = commit.id
            }
        } catch {
            errorMessage = "Commit failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func loadFiles() async {
        do {
            let files = try scanner.scan(folderURL: URL(fileURLWithPath: localState.localPath))
            self.musicFiles = files.filter { !$0.isDirectory }.map {
                MusicFile(
                    id: $0.id,
                    projectID: project.id,
                    name: $0.name,
                    fileExtension: $0.fileExtension,
                    path: $0.path,
                    capabilities: FileCapabilities.playable,
                    currentVersionID: "",
                    availableFormats: [],
                    createdAt: Date()
                )
            }
        } catch {
            errorMessage = "Failed to load files: \(error.localizedDescription)"
        }
    }
}
