//
//  BandInvitationRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol BandInvitationRepository {
    func fetchIncomingInvitations(for userID: String) async throws -> [BandInvitation]
    func fetchPendingInvitations(bandID: String) async throws -> [BandInvitation]
    func fetchExistingPendingInvitation(
        bandID: String,
        inviteeUserID: String
    ) async throws -> BandInvitation?
    func createInvitation(_ invitation: BandInvitation) async throws
    func acceptInvitation(_ invitation: BandInvitation) async throws
    func declineInvitation(_ invitation: BandInvitation) async throws
}
