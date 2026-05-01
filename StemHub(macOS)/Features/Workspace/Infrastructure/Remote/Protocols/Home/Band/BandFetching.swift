//
//  BandFetching.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol BandFetching: Sendable {
    func fetchBand(bandID: String) async throws -> Band?
}
