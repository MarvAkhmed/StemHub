//
//  FirestoreVersionRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreVersionRepository: VersionRepository, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchVersionHistory(projectID: String) async throws -> [ProjectVersion] {
        let snapshot = try await db.collection(FirestoreCollections.projectVersions.path)
            .whereField(FirestoreField.projectID.path, isEqualTo: projectID)
            .getDocuments()

        let versions = try snapshot.documents.map { try $0.data(as: ProjectVersion.self) }
        return sortedByParentChain(versions)
    }

    func fetchVersion(versionID: String) async throws -> ProjectVersion? {
        let doc = try await db.collection(FirestoreCollections.projectVersions.path)
            .document(versionID)
            .getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: ProjectVersion.self)
    }

    func fetchVersions(versionIDs: [String]) async throws -> [ProjectVersion] {
        guard !versionIDs.isEmpty else { return [] }

        let chunks = Array(Set(versionIDs)).chunked(into: 30)
        var results: [ProjectVersion] = []

        for chunk in chunks {
            let snapshot = try await db.collection(FirestoreCollections.projectVersions.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            results.append(contentsOf: try snapshot.documents.map { try $0.data(as: ProjectVersion.self) })
        }

        return results
    }

    func fetchFileVersions(fileVersionIDs: [String]) async throws -> [FileVersion] {
        guard !fileVersionIDs.isEmpty else { return [] }

        var results: [FileVersion] = []

        for chunk in fileVersionIDs.chunked(into: 30) {
            let querySnapshot = try await db.collection(FirestoreCollections.fileVersions.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            results.append(contentsOf: try querySnapshot.documents.map { try $0.data(as: FileVersion.self) })
        }

        return results
    }

    func approveVersion(versionID: String, approvedBy userID: String) async throws {
        try await db.collection(FirestoreCollections.projectVersions.path)
            .document(versionID)
            .updateData([
                FirestoreField.approvalState.path: ProjectVersionApprovalState.approved.rawValue,
                FirestoreField.approvedByUserID.path: userID,
                FirestoreField.approvedAt.path: Date()
            ])
    }
}

private extension FirestoreVersionRepository {
    func sortedByParentChain(_ versions: [ProjectVersion]) -> [ProjectVersion] {
        guard !versions.isEmpty else { return [] }
        guard versions.count > 1 else { return versions }

        let byID = Dictionary(versions.map { ($0.id, $0) }, uniquingKeysWith: { $1 })
        var remainingChildrenCount = Dictionary(
            uniqueKeysWithValues: versions.map { ($0.id, 0) }
        )
        for version in versions {
            guard let parentID = version.parentVersionID,
                  remainingChildrenCount[parentID] != nil else {
                continue
            }
            remainingChildrenCount[parentID, default: 0] += 1
        }

        var ready = versions
            .filter { remainingChildrenCount[$0.id, default: 0] == 0 }
            .sortedByVersionNumber()
        var result: [ProjectVersion] = []
        var visited = Set<String>()

        while !ready.isEmpty {
            let version = ready.removeFirst()
            guard visited.insert(version.id).inserted else { continue }

            result.append(version)

            guard let parentID = version.parentVersionID,
                  let parent = byID[parentID],
                  let remainingChildren = remainingChildrenCount[parentID] else {
                continue
            }

            remainingChildrenCount[parentID] = remainingChildren - 1
            if remainingChildrenCount[parentID] == 0 {
                ready.append(parent)
                ready = ready.sortedByVersionNumber()
            }
        }

        let unresolved = versions
            .filter { !visited.contains($0.id) }
            .sortedByVersionNumber()

        result.append(contentsOf: unresolved)
        return result
    }
}

private extension Array where Element == ProjectVersion {
    func sortedByVersionNumber() -> [ProjectVersion] {
        sorted { lhs, rhs in
            if lhs.versionNumber == rhs.versionNumber {
                return lhs.id < rhs.id
            }
            return lhs.versionNumber > rhs.versionNumber
        }
    }
}

// VERIFICATION
// - [ ] A version with a skewed createdAt is still ordered by graph topology.
// - [ ] A child version always appears before its parent; the root is last for a linear chain.
// - [ ] No version is dropped from the result regardless of its parentVersionID value.
// - [ ] fetchVersionHistory called with a project that has a single version returns
//       a one-element array containing that version.
// - [ ] fetchVersionHistory called with a project that has no versions returns [].
// - [ ] Detached versions are appended by versionNumber, not wall-clock timestamp.
// - [ ] A cycle in parentVersionID pointers does not cause an infinite loop (cycle guard).
