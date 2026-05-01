//
//  ProjectBranchError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum ProjectBranchError: LocalizedError {
    case invalidName
    case duplicateName
    case missingSourceVersion

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Branch name cannot be empty."
        case .duplicateName:
            return "A branch with this name already exists."
        case .missingSourceVersion:
            return "The branch needs a source version before it can be created."
        }
    }
}
