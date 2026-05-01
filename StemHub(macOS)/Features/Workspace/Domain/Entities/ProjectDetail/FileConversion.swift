//
//  FileConversion.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileConversion: Identifiable, Codable {
    let id: String
    let sourceBlobID: String
    let targetBlobID: String
    let fromFormat: String
    let toFormat: String
    let createdAt: Date
}
