//
//  LocalFile.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

struct LocalFile: Identifiable {
    let id = UUID().uuidString
    let path: String  // relative path inside project
    let name: String
    let fileExtension: String
    let size: Int64
    let hash: String
    let isDirectory: Bool
}
