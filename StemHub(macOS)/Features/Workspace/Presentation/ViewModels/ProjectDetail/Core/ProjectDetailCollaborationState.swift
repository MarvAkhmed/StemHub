//
//  ProjectDetailCollaborationState.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectDetailCollaborationState {
    var band: Band?
    var members: [User] = []
    var pendingInvitations: [BandInvitation] = []
}
