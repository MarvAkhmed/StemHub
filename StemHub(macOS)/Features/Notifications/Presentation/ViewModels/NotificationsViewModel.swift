//
//  NotificationsViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Combine
import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published private(set) var invitations: [BandInvitation] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authService: any AuthenticatedUserProviding
    private let invitationService: BandInvitationServiceProtocol
    private var hasLoaded = false

    var pendingInvitationCount: Int {
        invitations.filter { $0.status == .pending }.count
    }

    var pendingInvitations: [BandInvitation] {
        invitations.filter { $0.status == .pending }
    }

    var resolvedInvitations: [BandInvitation] {
        invitations.filter { $0.status != .pending }
    }

    init(
        authService: any AuthenticatedUserProviding,
        invitationService: BandInvitationServiceProtocol
    ) {
        self.authService = authService
        self.invitationService = invitationService
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard let userID = authService.currentUser?.id else {
            errorMessage = "User not logged in"
            invitations = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            invitations = try await invitationService.fetchIncomingInvitations(for: userID)
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func respond(
        to invitation: BandInvitation,
        action: BandInvitationResponseAction
    ) async {
        guard let userID = authService.currentUser?.id else {
            errorMessage = "User not logged in"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await invitationService.respond(
                to: invitation,
                action: action,
                currentUserID: userID
            )
            invitations = try await invitationService.fetchIncomingInvitations(for: userID)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }
}
