//
//  CommitFileSnapshot.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct CommitFileSnapshot: Codable {
    let fileID: String
    let path: String
    
    let blobID: String
    let hash: String
    
    let versionNumber: Int
}
