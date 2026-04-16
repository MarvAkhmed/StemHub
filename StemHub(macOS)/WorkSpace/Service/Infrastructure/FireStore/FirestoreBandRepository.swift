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

    func createBand(name: String, userID: String) async throws -> Band {
        try await firestore.createBand(name: name, userID: userID)
    }

    func addBand(to userID: String, bandID: String) async throws {
        try await firestore.addBand(to: userID, bandID: bandID)
    }
}
