//
//  Band.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct Band: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    
    var memberIDs: [String]
    var projectIDs: [String]
    
    let createdAt: Date
}
