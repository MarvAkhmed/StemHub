//
//  BandInvitationService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum BandInvitationResponseAction {
    case accept
    case decline
}

protocol BandInvitationServiceProtocol {
    func fetchIncomingInvitations(for userID: String) async throws -> [BandInvitation]
    func fetchPendingInvitations(bandID: String) async throws -> [BandInvitation]
    func sendInvitation(
        email: String,
        bandID: String,
        bandName: String,
        requestedBy userID: String
    ) async throws -> BandInvitation
    func respond(
        to invitation: BandInvitation,
        action: BandInvitationResponseAction,
        currentUserID: String
    ) async throws
}

final class BandInvitationService: BandInvitationServiceProtocol {
    private let invitationRepository: BandInvitationRepository
    private let bandRepository: any BandFetching
    private let userRepository: any UserDirectoryReading & UserEmailLookup

    init(
        invitationRepository: BandInvitationRepository,
        bandRepository: any BandFetching,
        userRepository: any UserDirectoryReading & UserEmailLookup
    ) {
        self.invitationRepository = invitationRepository
        self.bandRepository = bandRepository
        self.userRepository = userRepository
    }

    func fetchIncomingInvitations(for userID: String) async throws -> [BandInvitation] {
        try await invitationRepository.fetchIncomingInvitations(for: userID)
    }

    func fetchPendingInvitations(bandID: String) async throws -> [BandInvitation] {
        try await invitationRepository.fetchPendingInvitations(bandID: bandID)
    }

    func sendInvitation(
        email: String,
        bandID: String,
        bandName: String,
        requestedBy userID: String
    ) async throws -> BandInvitation {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.contains("@") else {
            throw BandInvitationError.invalidEmail
        }

        guard let band = try await bandRepository.fetchBand(bandID: bandID) else {
            throw BandInvitationError.bandNotFound
        }

        guard band.isAdmin(userID: userID) else {
            throw BandInvitationError.unauthorized
        }

        guard let invitee = try await userRepository.fetchUser(email: normalizedEmail) else {
            throw BandInvitationError.userNotFound
        }

        guard invitee.id != userID else {
            throw BandInvitationError.cannotInviteYourself
        }

        guard band.memberIDs.contains(invitee.id) == false else {
            throw BandInvitationError.alreadyMember
        }

        guard try await invitationRepository.fetchExistingPendingInvitation(
            bandID: bandID,
            inviteeUserID: invitee.id
        ) == nil else {
            throw BandInvitationError.duplicateInvitation
        }

        let requester = try await userRepository.fetchUser(userId: userID)
        let invitation = BandInvitation(
            id: UUID().uuidString,
            bandID: bandID,
            bandName: bandName,
            inviteeUserID: invitee.id,
            inviteeEmail: invitee.email ?? normalizedEmail,
            requestedByUserID: userID,
            requestedByName: requester?.name,
            status: .pending,
            createdAt: Date(),
            respondedAt: nil
        )

        try await invitationRepository.createInvitation(invitation)
        return invitation
    }

    func respond(
        to invitation: BandInvitation,
        action: BandInvitationResponseAction,
        currentUserID: String
    ) async throws {
        guard invitation.inviteeUserID == currentUserID else {
            throw BandInvitationError.unauthorized
        }

        switch action {
        case .accept:
            try await invitationRepository.acceptInvitation(invitation)
        case .decline:
            try await invitationRepository.declineInvitation(invitation)
        }
    }
}

enum BandInvitationError: LocalizedError {
    case invalidEmail
    case bandNotFound
    case unauthorized
    case userNotFound
    case cannotInviteYourself
    case alreadyMember
    case duplicateInvitation

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .bandNotFound:
            return "The selected band could not be found."
        case .unauthorized:
            return "Only the band admin can manage invitations."
        case .userNotFound:
            return "No StemHub user was found with that email address."
        case .cannotInviteYourself:
            return "You are already part of this band."
        case .alreadyMember:
            return "That collaborator is already in this band."
        case .duplicateInvitation:
            return "There is already a pending invitation for this collaborator."
        }
    }
}
