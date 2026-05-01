//
//  ProjectDetailError.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum ProjectDetailError: LocalizedError {
    case userNotSignedIn
    case missingBranch
    case missingProjectFolder
    case folderNotWritable
    case missingSelectedFile
    case missingVersionContext

    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "You need to be signed in to update this project."
        case .missingBranch:
            return "No branch is currently selected."
        case .missingProjectFolder:
            return "The local project folder could not be found."
        case .folderNotWritable:
            return "The local project folder is not writable."
        case .missingSelectedFile:
            return "Select a file before adding a comment."
        case .missingVersionContext:
            return "Comments need a saved project version first."
        }
    }
}
