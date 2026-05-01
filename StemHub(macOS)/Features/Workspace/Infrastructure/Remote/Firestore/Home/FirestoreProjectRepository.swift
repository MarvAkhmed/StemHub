//
//  FirestoreProjectRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreProjectRepository: ProjectRepository, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchProjects(for userID: String) async throws -> [Project] {
        let userSnapshot = try await db.collection(FirestoreCollections.users.path)
            .document(userID)
            .getDocument()
        let bandIDs = userSnapshot.data()?[FirestoreField.bandIDs.path] as? [String] ?? []
        guard !bandIDs.isEmpty else { return [] }

        var projects: [Project] = []
        for chunk in bandIDs.chunked(into: 30) {
            let snapshot = try await db.collection(FirestoreCollections.projects.path)
                .whereField(FirestoreField.bandID.path, in: chunk)
                .getDocuments()
            projects.append(contentsOf: try snapshot.documents.map { try $0.data(as: Project.self) })
        }

        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }

    func createProject(_ project: Project, initialBranch: Branch) async throws {
        let batch = db.batch()
        try batch.setData(
            from: project,
            forDocument: db.collection(FirestoreCollections.projects.path).document(project.id)
        )
        try batch.setData(
            from: initialBranch,
            forDocument: db.collection(FirestoreCollections.branches.path).document(initialBranch.id)
        )
        batch.updateData(
            [FirestoreField.projectIDs.path: FieldValue.arrayUnion([project.id])],
            forDocument: db.collection(FirestoreCollections.bands.path).document(project.bandID)
        )
        try await batch.commit()
    }

    func deleteProject(projectID: String, bandID: String) async throws {
        let versionSnapshot = try await db.collection(FirestoreCollections.projectVersions.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
            .getDocuments()
        
        let branchSnapshot = try await db.collection(FirestoreCollections.branches.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
            .getDocuments()
        
        let commentSnapshot = try await db.collection(FirestoreCollections.comments.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
            .getDocuments()
        
        let commitSnapshot = try await db.collection(FirestoreCollections.commits.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
            .getDocuments()

        let fileVersionIDs = fileVersionIDs(from: versionSnapshot.documents)
        let fileVersionReferences = fileVersionIDs.map {
            db.collection(FirestoreCollections.fileVersions.path).document($0)
        }
        
        let blobReferences = try await unreferencedBlobReferences(fileVersionIDs: fileVersionIDs, bandID: bandID)

        var referencesToDelete = [db.collection(FirestoreCollections.projects.path).document(projectID)]
        referencesToDelete.append(contentsOf: versionSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: branchSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: commentSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: commitSnapshot.documents.map(\.reference))
        referencesToDelete.append(contentsOf: fileVersionReferences)
        referencesToDelete.append(contentsOf: blobReferences)

        for chunk in referencesToDelete.chunked(into: 400) {
            let batch = db.batch()
            for reference in chunk {
                batch.deleteDocument(reference)
            }
            try await batch.commit()
        }

        try await db.collection(FirestoreCollections.bands.path)
            .document(bandID)
            .updateData([
                FirestoreField.projectIDs.path: FieldValue.arrayRemove([projectID])
            ])
    }

    func fetchBlobStoragePaths(projectID: String, bandID: String) async throws -> [String] {
        let versionSnapshot = try await db.collection(FirestoreCollections.projectVersions.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
            .getDocuments()
        let fileVersionIDs = fileVersionIDs(from: versionSnapshot.documents)
        guard !fileVersionIDs.isEmpty else { return [] }

        let projectBlobIDs = try await blobIDs(fileVersionIDs: fileVersionIDs, bandID: bandID)

        var storagePaths = Set(projectBlobIDs.map { blobStoragePrefix(projectID: projectID) + $0 })
        for chunk in Array(projectBlobIDs).chunked(into: 30) {
            let snapshot = try await db.collection(FirestoreCollections.blobs.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
                .getDocuments()
            let blobs = try snapshot.documents.map { try $0.data(as: FileBlob.self) }
            storagePaths.formUnion(
                blobs
                    .map(\.storagePath)
                    .filter { $0.hasPrefix(blobStoragePrefix(projectID: projectID)) }
            )
        }
        return storagePaths.sorted()
    }

    func isDuplicateProject(name: String, bandID: String) async throws -> Bool {
        let snapshot = try await db
            .collection(FirestoreCollections.projects.path)
            .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
            .whereField(FirestoreField.name.path, isEqualTo: name)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    func updatePosterBase64(projectID: String, base64: String) async throws {
        try await db
            .collection(FirestoreCollections.projects.path)
            .document(projectID)
            .updateData([
                FirestoreField.posterBase64.path: base64,
                FirestoreField.updatedAt.path: Date()
            ])
    }

    func updateWorkspaceState(projectID: String, currentBranchID: String, currentVersionID: String?) async throws {
        try await db
            .collection(FirestoreCollections.projects.path)
            .document(projectID)
            .updateData([
                FirestoreField.currentBranchID.path: currentBranchID,
                FirestoreField.currentVersionID.path: currentVersionID ?? "",
                FirestoreField.updatedAt.path: Date()
            ])
    }
}

private extension FirestoreProjectRepository {
    func fileVersionIDs(from versionDocuments: [QueryDocumentSnapshot]) -> [String] {
        Array(Set(versionDocuments.flatMap {
            $0.data()[FirestoreField.fileVersionIDs.path] as? [String] ?? []
        }))
    }

    func unreferencedBlobReferences(fileVersionIDs: [String], bandID: String) async throws -> [DocumentReference] {
        let projectFileVersionIDs = Set(fileVersionIDs)
        let blobIDs = try await blobIDs(fileVersionIDs: fileVersionIDs, bandID: bandID)
        var references: [DocumentReference] = []

        for blobID in blobIDs {
            let snapshot = try await db.collection(FirestoreCollections.fileVersions.path)
                .whereField(FirestoreField.blobID.path, isEqualTo: blobID)
                .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
                .getDocuments()
            let hasExternalReference = snapshot.documents.contains {
                !projectFileVersionIDs.contains($0.documentID)
            }

            if !hasExternalReference {
                references.append(db.collection(FirestoreCollections.blobs.path).document(blobID))
            }
        }

        return references
    }

    func blobIDs(fileVersionIDs: [String], bandID: String) async throws -> Set<String> {
        guard !fileVersionIDs.isEmpty else { return [] }

        var blobIDs = Set<String>()
        for chunk in fileVersionIDs.chunked(into: 30) {
            let snapshot = try await db.collection(FirestoreCollections.fileVersions.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .whereField(FirestoreField.bandID.path, isEqualTo: bandID)
                .getDocuments()
            let fileVersions = try snapshot.documents.map { try $0.data(as: FileVersion.self) }
            blobIDs.formUnion(fileVersions.map(\.blobID))
        }

        return blobIDs
    }

    func blobStoragePrefix(projectID: String) -> String {
        "projects/\(projectID)/blobs/"
    }
}
