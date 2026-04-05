//
//  FileNode.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct FileNode: Identifiable, Codable {
    let id: String
    
    let name: String
    let type: FileType
    
    let parentID: String?
    
    let fileID: String? // if it's a file
}
