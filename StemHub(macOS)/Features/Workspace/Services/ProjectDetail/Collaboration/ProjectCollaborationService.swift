//
//  ProjectCollaborationService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol ProjectCollaborationServiceProtocol {
    func fetchBand(bandID: String) async throws -> Band?
    func fetchMembers(bandID: String) async throws -> [User]
    func fetchPendingInvitations(bandID: String) async throws -> [BandInvitation]
    func inviteMember(
        email: String,
        bandID: String,
        bandName: String,
        requestedBy userID: String
    ) async throws -> [BandInvitation]
}

final class ProjectCollaborationService: ProjectCollaborationServiceProtocol {
    private let bandRepository: any BandFetching
    private let userRepository: any UserDirectoryReading
    private let invitationService: BandInvitationServiceProtocol

    init(
        bandRepository: any BandFetching,
        userRepository: any UserDirectoryReading,
        invitationService: BandInvitationServiceProtocol
    ) {
        self.bandRepository = bandRepository
        self.userRepository = userRepository
        self.invitationService = invitationService
    }

    func fetchBand(bandID: String) async throws -> Band? {
        try await bandRepository.fetchBand(bandID: bandID)
    }

    func fetchMembers(bandID: String) async throws -> [User] {
        guard let band = try await bandRepository.fetchBand(bandID: bandID) else {
            return []
        }

        let members = try await userRepository.fetchUsers(userIDs: band.memberIDs)
        return members.sorted { ($0.email ?? "") < ($1.email ?? "") }
    }

    func fetchPendingInvitations(bandID: String) async throws -> [BandInvitation] {
        try await invitationService.fetchPendingInvitations(bandID: bandID)
    }

    func inviteMember(
        email: String,
        bandID: String,
        bandName: String,
        requestedBy userID: String
    ) async throws -> [BandInvitation] {
        _ = try await invitationService.sendInvitation(
            email: email,
            bandID: bandID,
            bandName: bandName,
            requestedBy: userID
        )
        return try await fetchPendingInvitations(bandID: bandID)
    }
}
