//
//  ProjectDiff.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

struct ProjectDiff: Codable, Sendable {
    let files: [FileDiff]
}

extension ProjectDiff {
    
    var added: [FileDiff] {
        files.filter { $0.changeType == .added }
    }
    
    var modified: [FileDiff] {
        files.filter { $0.changeType == .modified }
    }
    
    var removed: [FileDiff] {
        files.filter { $0.changeType == .removed }
    }
    
    var renamed: [FileDiff] {
        files.filter { $0.changeType == .renamed }
    }
}
