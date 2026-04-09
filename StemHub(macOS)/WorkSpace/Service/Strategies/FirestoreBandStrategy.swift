//
//  FirestoreBandStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore

protocol FirestoreBandStrategy {
    func createBand(name: String, userID: String) async throws -> Band
    func addBand(to userID: String, bandID: String) async throws
    func fetchBands(for userID: String) async throws -> [Band]
    func fetchBand(bandID: String) async throws -> Band?
}

struct DefaultFirestoreBandStrategy: FirestoreBandStrategy {
    private let db = Firestore.firestore()
    
    func createBand(name: String, userID: String) async throws -> Band {
        let band = Band(
            id: UUID().uuidString,
            name: name,
            memberIDs: [userID],
            projectIDs: [],
            createdAt: Date()
        )
        try db.collection("bands").document(band.id).setData(from: band)
        return band
    }
    
    func addBand(to userID: String, bandID: String) async throws {
        try await db.collection("users").document(userID).updateData([
            "bandIDs": FieldValue.arrayUnion([bandID])
        ])
    }
    
    func fetchBands(for userID: String) async throws -> [Band] {
        let userDoc = try await db.collection("users").document(userID).getDocument()
        guard let user = try? userDoc.data(as: User.self) else { return [] }
        
        var bands: [Band] = []
        for bandID in user.bandIDs {
            if let band = try await fetchBand(bandID: bandID) {
                bands.append(band)
            }
        }
        return bands
    }
    
    func fetchBand(bandID: String) async throws -> Band? {
        let doc = try await db.collection("bands").document(bandID).getDocument()
        return try? doc.data(as: Band.self)
    }
}
