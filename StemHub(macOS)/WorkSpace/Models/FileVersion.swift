//
//  FileVersion.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileVersion: Identifiable, Codable {
    let id: String
    
    let fileID: String
    let blobID: String 
    
    let path: String
    
    let versionNumber: Int
    
    var syncStatus: SyncStatus
    
    let createdAt: Date
}
