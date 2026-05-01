//
//  FirestoreBandRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreBandRepository: BandRepository, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore ) {
        self.db = db
    }

    func fetchBands(for userID: String) async throws -> [Band] {
        let userDoc = try await db.collection(FirestoreCollections.users.path)
            .document(userID)
            .getDocument()
        guard let bandIDs = userDoc.data()?[FirestoreField.bandIDs.path] as? [String] else { return [] }

        var bands: [Band] = []
        for chunk in bandIDs.chunked(into: 30) {
            let snapshot = try await db.collection(FirestoreCollections.bands.path)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            bands.append(contentsOf: try snapshot.documents.map { try $0.data(as: Band.self) })
        }

        return bands.sorted {
            let nameComparison = $0.name.localizedCaseInsensitiveCompare($1.name)
            if nameComparison == .orderedSame {
                return $0.createdAt < $1.createdAt
            }
            return nameComparison == .orderedAscending
        }
    }

    func fetchBand(bandID: String) async throws -> Band? {
        let document = try await db.collection(FirestoreCollections.bands.path)
            .document(bandID)
            .getDocument()
        guard document.exists else { return nil }
        return try document.data(as: Band.self)
    }

    func createBand(_ band: Band) async throws {
        try db.collection(FirestoreCollections.bands.path)
            .document(band.id)
            .setData(from: band)
    }

    func addBand(_ bandID: String, to userId: String) async throws {
        try await db.collection(FirestoreCollections.users.path)
            .document(userId)
            .updateData([FirestoreField.bandIDs.path: FieldValue.arrayUnion([bandID])])
    }
}
