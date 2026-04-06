//
//  FileBlob.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileBlob: Identifiable, Codable {
    let id: String 
    
    let storagePath: String
    let size: Int64
    
    let hash: String // SHA256
    
    let createdAt: Date
}
