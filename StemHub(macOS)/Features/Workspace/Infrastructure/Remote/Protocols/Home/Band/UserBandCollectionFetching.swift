//
//  UserBandCollectionFetching.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol UserBandCollectionFetching: Sendable {
    func fetchBands(for userID: String) async throws -> [Band]
}
