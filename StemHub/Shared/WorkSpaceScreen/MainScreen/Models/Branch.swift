//
//  Branch.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct Branch: Identifiable, Codable {
    let id: String
    let projectID: String
    var name: String
    
    var headVersionID: String?        // last commit on this branch
    
    let createdAt: Date
    let createdBy: String
}
