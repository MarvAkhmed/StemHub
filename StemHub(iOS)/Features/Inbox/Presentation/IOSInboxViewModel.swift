//
//  IOSInboxViewModel.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import Combine

@MainActor
final class IOSInboxViewModel: ObservableObject {
    @Published private(set) var invitations: [IOSBandInvitation] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authService: any AuthenticatedUserProviding
    private let repository: any IOSInvitationManaging
    private var hasLoaded = false

    init(
        authService: any AuthenticatedUserProviding,
        repository: any IOSInvitationManaging
    ) {
        self.authService = authService
        self.repository = repository
    }

    var pendingInvitationCount: Int {
        invitations.filter { $0.status == .pending }.count
    }

    var pendingInvitations: [IOSBandInvitation] {
        invitations.filter { $0.status == .pending }
    }

    var resolvedInvitations: [IOSBandInvitation] {
        invitations.filter { $0.status != .pending }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard let userID = authService.currentUser?.id else {
            invitations = []
            errorMessage = "User not logged in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            invitations = try await repository.fetchIncomingInvitations(for: userID)
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func respond(
        to invitation: IOSBandInvitation,
        action: IOSInvitationDecision
    ) async {
        guard let userID = authService.currentUser?.id else {
            errorMessage = "User not logged in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await repository.respond(
                to: invitation,
                action: action,
                currentUserID: userID
            )
            invitations = try await repository.fetchIncomingInvitations(for: userID)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }
}
