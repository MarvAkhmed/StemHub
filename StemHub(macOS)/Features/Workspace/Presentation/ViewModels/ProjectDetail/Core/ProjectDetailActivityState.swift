//
//  ProjectDetailActivityState.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum ProjectDetailActivityState: Equatable {
    case idle
    case loading
    case pulling
    case committing
    case pushing
    case importingFiles
    case switchingBranch
    case creatingBranch
    case invitingMember
    case savingComment
    case savingPoster
    case fixingFolder
    case relocatingFolder
    case openingMIDIEditor
    case approvingVersion

    var isLoading: Bool {
        self != .idle
    }
}
