//
//  DefaultFirestoreVersionStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore

protocol FirestoreVersionStrategy {
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion]
    func fetchVersion(versionID: String) async throws -> ProjectVersion?
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion]
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
}

struct DefaultFirestoreVersionStrategy: FirestoreVersionStrategy {
    private let db = Firestore.firestore()
    
    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        do {
            let snapshot = try await db.collection("projectVersions")
                .whereField("projectID", isEqualTo: projectID)
                .order(by: "versionNumber", descending: true)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
        } catch {
            print("Index not ready, fetching without order")
            let snapshot = try await db.collection("projectVersions")
                .whereField("projectID", isEqualTo: projectID)
                .getDocuments()
            var versions = snapshot.documents.compactMap { try? $0.data(as: ProjectVersion.self) }
            versions.sort { $0.versionNumber > $1.versionNumber }
            return versions
        }
    }
    
    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        guard !versionID.isEmpty else { return nil }
        let doc = try await db.collection("projectVersions").document(versionID).getDocument()
        return try? doc.data(as: ProjectVersion.self)
    }
    
    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion] {
        var fileVersions: [FileVersion] = []
        for id in fileVersionIDs where !id.isEmpty {
            do {
                let doc = try await db.collection("fileVersions").document(id).getDocument()
                if let fv = try? doc.data(as: FileVersion.self) {
                    fileVersions.append(fv)
                }
            } catch {
                print("Failed to fetch file version \(id): \(error)")
            }
        }
        return fileVersions
    }
    
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot] {
        guard !versionID.isEmpty else { return [] }
        
        let versionDoc = try await db.collection("projectVersions").document(versionID).getDocument()
        guard versionDoc.exists else { return [] }
        
        let projectVersion = try versionDoc.data(as: ProjectVersion.self)
        
        var snapshots: [RemoteFileSnapshot] = []
        for fileVersionID in projectVersion.fileVersionIDs {
            guard !fileVersionID.isEmpty else { continue }
            
            let fvDoc = try await db.collection("fileVersions").document(fileVersionID).getDocument()
            guard fvDoc.exists else { continue }
            
            let fv = try fvDoc.data(as: FileVersion.self)
            snapshots.append(RemoteFileSnapshot(
                fileID: fv.fileID,
                path: fv.path,
                hash: fv.blobID,
                versionID: projectVersion.id
            ))
        }
        return snapshots
    }
}
