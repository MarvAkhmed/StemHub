//
//  ProjectCreationServiceError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

enum ProjectCreationServiceError: LocalizedError {
    case invalidName
    case missingFolder
    case invalidBandName
    case duplicateName

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Project name cannot be empty."
        case .missingFolder:
            return "Project folder is required."
        case .invalidBandName:
            return "Enter a band name or select one of your existing bands."
        case .duplicateName:
            return "A project with this name already exists in that band."
        }
    }
}
