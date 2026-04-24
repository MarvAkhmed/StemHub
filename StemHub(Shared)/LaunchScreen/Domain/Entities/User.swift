//
//  User.swift
//  StemHub
//
//  Created by Marwa Awad on 30.03.2026.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let name: String?
    let email: String?
    let password: String?
    var bandIDs: [String] = []
}

