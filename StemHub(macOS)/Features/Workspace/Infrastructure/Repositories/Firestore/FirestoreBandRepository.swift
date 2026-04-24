//
//  FirestoreBandRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreBandRepository: BandRepository {
    private let firestore: FirestoreManager

    init(firestore: FirestoreManager = .shared) {
        self.firestore = firestore
    }

    func fetchBands(for userID: String) async throws -> [Band] {
        let userDoc = try await firestore.firestore().collection("users").document(userID).getDocument()
        guard let bandIDs = userDoc.data()?["bandIDs"] as? [String] else { return [] }

        var bands: [Band] = []
        for bandID in bandIDs {
            let bandDoc = try await firestore.firestore().collection("bands").document(bandID).getDocument()
            if let band = try? bandDoc.data(as: Band.self) {
                bands.append(band)
            }
        }
        return bands
    }

    func fetchBand(bandID: String) async throws -> Band? {
        try await firestore.fetchBand(bandID: bandID)
    }

    func createBand(
        name: String,
        primaryAdminUserID: String,
        adminUserIDs: [String],
        memberUserIDs: [String]
    ) async throws -> Band {
        try await firestore.createBand(
            name: name,
            primaryAdminUserID: primaryAdminUserID,
            adminUserIDs: adminUserIDs,
            memberUserIDs: memberUserIDs
        )
    }

    func addBand(to userID: String, bandID: String) async throws {
        try await firestore.addBand(to: userID, bandID: bandID)
    }

    func addMember(userID: String, to bandID: String) async throws {
        try await firestore.addMember(userID: userID, to: bandID)
    }

    func linkProject(_ projectID: String, to bandID: String) async throws {
        try await firestore.linkProject(projectID, to: bandID)
    }
}
