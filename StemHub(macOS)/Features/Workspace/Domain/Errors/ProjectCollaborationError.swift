//
//  ProjectCollaborationError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum ProjectCollaborationError: LocalizedError {
    case unauthorized
    case userNotFound
    case invalidEmail
    case duplicateMember
    case bandNotFound

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Only the project admin can manage members."
        case .userNotFound:
            return "No user was found for that email."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .duplicateMember:
            return "That user is already a member of this project band."
        case .bandNotFound:
            return "The project band could not be found."
        }
    }
}
