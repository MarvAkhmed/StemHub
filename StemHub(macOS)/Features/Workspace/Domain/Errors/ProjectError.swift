//
//  ProjectError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation

enum ProjectError: LocalizedError {
    case duplicateName
    
    var errorDescription: String? {
        switch self {
        case .duplicateName:
            return "A project with this name already exists in the band."
        }
    }
}
