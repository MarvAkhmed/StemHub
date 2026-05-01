//
//  FirestoreIOSReleaseCatalog.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import FirebaseFirestore

protocol IOSReleaseCatalogProviding {
    func fetchReleaseCandidates(for userID: String) async throws -> [IOSReleaseCandidate]
}

final class FirestoreIOSReleaseCatalog: IOSReleaseCatalogProviding {
    private let workspaceRepository: any IOSWorkspaceLoading
    private let db: Firestore

    init(
        workspaceRepository: any IOSWorkspaceLoading,
        db: Firestore
    ) {
        self.workspaceRepository = workspaceRepository
        self.db = db
    }

    func fetchReleaseCandidates(for userID: String) async throws -> [IOSReleaseCandidate] {
        let snapshot = try await workspaceRepository.fetchWorkspace(for: userID)
        let bandLookup = Dictionary(uniqueKeysWithValues: snapshot.bands.map { ($0.id, $0) })

        return try await withThrowingTaskGroup(of: IOSReleaseCandidate?.self) { group in
            for project in snapshot.projects {
                group.addTask { [db] in
                    let version = try await Self.latestApprovedVersion(for: project.id, using: db)
                    guard let version else { return nil }
                    let band = bandLookup[project.bandID]

                    return IOSReleaseCandidate(
                        id: project.id,
                        projectName: project.name,
                        bandName: band?.name ?? "Independent",
                        latestVersionLabel: "Version \(version.versionNumber)",
                        latestActivity: version.createdAt,
                        isBandAdmin: band?.adminUserID == userID,
                        artworkBase64: project.posterBase64
                    )
                }
            }

            var candidates: [IOSReleaseCandidate] = []
            for try await candidate in group {
                if let candidate {
                    candidates.append(candidate)
                }
            }

            return candidates.sorted { $0.latestActivity > $1.latestActivity }
        }
    }

    private static func latestApprovedVersion(
        for projectID: String,
        using db: Firestore
    ) async throws -> IOSProjectVersionRecord? {
        let snapshot = try await db.collection("projectVersions")
            .whereField("projectID", isEqualTo: projectID)
            .getDocuments()

        return snapshot.documents
            .compactMap { $0.decoded(as: IOSProjectVersionRecord.self) }
            .filter { $0.approvalState == "approved" }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id > rhs.id
                }
                return lhs.createdAt > rhs.createdAt
            }
            .first
    }
}
