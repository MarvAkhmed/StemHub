//
//  BandCreationPersisting.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

protocol BandCreationPersisting: Sendable {
    func createBand(_ band: Band) async throws
    func addBand(_ bandID: String, to userId: String) async throws
}
