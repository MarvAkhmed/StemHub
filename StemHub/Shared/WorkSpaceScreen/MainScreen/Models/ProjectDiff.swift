//
//  ProjectDiff.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct ProjectDiff: Codable {
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
