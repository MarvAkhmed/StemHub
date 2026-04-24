//
//  BandRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

protocol UserBandCollectionFetching {
    func fetchBands(for userID: String) async throws -> [Band]
}

protocol BandFetching {
    func fetchBand(bandID: String) async throws -> Band?
}

protocol BandCreating {
    func createBand(
        name: String,
        primaryAdminUserID: String,
        adminUserIDs: [String],
        memberUserIDs: [String]
    ) async throws -> Band
}

protocol UserBandLinking {
    func addBand(to userID: String, bandID: String) async throws
}

protocol BandMemberManaging {
    func addMember(userID: String, to bandID: String) async throws
}

protocol BandProjectLinking {
    func linkProject(_ projectID: String, to bandID: String) async throws
}

protocol BandRepository:
    UserBandCollectionFetching,
    BandFetching,
    BandCreating,
    UserBandLinking,
    BandMemberManaging,
    BandProjectLinking {}
