//
//  NotificationsView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel

    var body: some View {
        ZStack {
            StudioBackdropView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    pendingSection

                    if !viewModel.resolvedInvitations.isEmpty {
                        historySection
                    }
                }
                .padding(28)
            }
        }
        .studioSafeArea()
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert("Notifications", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearError()
                }
            }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private extension NotificationsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Band Invitations")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)

            Text("Accept or decline invites without losing focus in the workspace.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.76))
        }
    }

    var pendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Awaiting Your Answer")

            if viewModel.pendingInvitations.isEmpty {
                contentCard {
                    ContentUnavailableView(
                        "No Pending Invites",
                        systemImage: "checkmark.circle",
                        description: Text("When a band admin invites you, it will land here.")
                    )
                    .foregroundStyle(.white.opacity(0.92))
                }
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.pendingInvitations) { invitation in
                        invitationCard(invitation)
                    }
                }
            }
        }
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Recent Decisions")

            LazyVStack(spacing: 12) {
                ForEach(viewModel.resolvedInvitations) { invitation in
                    contentCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(invitation.bandName)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(statusText(for: invitation))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.72))
                            }

                            Spacer()

                            invitationStatusBadge(invitation.status)
                        }
                    }
                }
            }
        }
    }

    func invitationCard(_ invitation: BandInvitation) -> some View {
        contentCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(invitation.bandName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Invited by \(invitation.requestedByName ?? "Band Admin")")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.74))

                    Text(invitation.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                }

                HStack(spacing: 12) {
                    Button("Accept") {
                        Task { await viewModel.respond(to: invitation, action: .accept) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.77, green: 0.53, blue: 0.98))
                    .disabled(viewModel.isLoading)

                    Button("Decline") {
                        Task { await viewModel.respond(to: invitation, action: .decline) }
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.white)
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))
    }

    func contentCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .studioGlassPanel(cornerRadius: 24, padding: 18)
    }

    func invitationStatusBadge(_ status: BandInvitationStatus) -> some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(
                    status == .accepted
                    ? Color.green.opacity(0.22)
                    : Color.white.opacity(0.12)
                )
            )
            .foregroundStyle(.white)
    }

    func statusText(for invitation: BandInvitation) -> String {
        switch invitation.status {
        case .pending:
            return "Still waiting for your decision."
        case .accepted:
            return "You joined this band."
        case .declined:
            return "You passed on this invite."
        }
    }
}
