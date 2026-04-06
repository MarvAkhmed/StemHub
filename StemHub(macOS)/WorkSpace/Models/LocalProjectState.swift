//
//  LocalProjectState.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct LocalProjectState: Codable {
    let projectID: String
    
    let localPath: String
    
    var lastPulledVersionID: String?  // remote HEAD
    var lastCommittedID: String?  // local HEAD
    var currentBranchID: String?

}
