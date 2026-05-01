//
//  FirebaseFirestoreCollections.swift
//  StemHub
//
//  Created by Marwa Awad on 26.04.2026.
//

import Foundation

enum FirestoreCollections: String, Sendable {
    case users
    case bands
    case bandInvitations
    case projects
    case branches
    case blobs
    case commits
    case fileVersions
    case projectVersions
    case comments

    var path: String {
        rawValue
    }
}
