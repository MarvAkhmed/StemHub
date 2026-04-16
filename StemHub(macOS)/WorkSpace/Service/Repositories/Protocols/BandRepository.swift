//
//  BandRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation
import FirebaseFirestore

protocol BandRepository {
    func fetchBands(for userID: String) async throws -> [Band]
    func createBand(name: String, userID: String) async throws -> Band
    func addBand(to userID: String, bandID: String) async throws
}
