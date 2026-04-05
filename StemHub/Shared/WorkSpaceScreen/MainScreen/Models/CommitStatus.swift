//
//  CommitStatus.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

enum CommitStatus: String, Codable {
    case local       // not pushed yet
    case pushing
    case pushed
    case failed
}
