//
//  RemoteBlobByteCleaning.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

protocol RemoteBlobByteCleaning: Sendable {
    func deleteBlobBytes(storagePaths: [String]) async throws
}
