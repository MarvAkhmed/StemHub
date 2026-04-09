//
//  FirestoreRemoteFetch.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseFirestore

protocol RemoteFetchStrategy {
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
    func fetchProjectVersion(versionID: String) async throws -> ProjectVersion?
}


struct FirestoreRemoteFetch: RemoteFetchStrategy {
    private let db = Firestore.firestore()
    
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
    
    func fetchProjectVersion(versionID: String) async throws -> ProjectVersion? {
        guard !versionID.isEmpty else { return nil }
        
        let doc = try await db.collection("projectVersions").document(versionID).getDocument()
        return try? doc.data(as: ProjectVersion.self)
    }
}
