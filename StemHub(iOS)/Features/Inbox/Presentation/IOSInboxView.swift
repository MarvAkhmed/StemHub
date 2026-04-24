//
//  IOSInboxView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct IOSInboxView: View {
    @ObservedObject var viewModel: IOSInboxViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                pendingSection

                if !viewModel.resolvedInvitations.isEmpty {
                    historySection
                }
            }
            .padding(20)
        }
        .iosStudioScreenBackground()
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .tint(.white)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert("Inbox", isPresented: Binding(
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

private extension IOSInboxView {
    var header: some View {
        IOSStudioCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Band invites and collaboration updates")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Accept or decline invitations without leaving your mobile review flow.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 10) {
                    IOSMetricPill(value: "\(viewModel.pendingInvitationCount)", label: "Pending")
                    IOSMetricPill(value: "\(viewModel.resolvedInvitations.count)", label: "Resolved")
                }
            }
        }
    }

    var pendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            IOSSectionHeader("Awaiting your answer")

            if viewModel.pendingInvitations.isEmpty {
                IOSStudioCard {
                    ContentUnavailableView(
                        "No Pending Invites",
                        systemImage: "checkmark.circle",
                        description: Text("When a band admin adds you to a band, it will show up here.")
                    )
                    .foregroundStyle(.white.opacity(0.90))
                }
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.pendingInvitations) { invitation in
                        IOSStudioCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(invitation.bandName)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text("Invited by \(invitation.requestedByName ?? "Band Admin")")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.72))

                                Text(invitation.createdAt.formatted(.dateTime.month().day().hour().minute()))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.58))

                                HStack(spacing: 12) {
                                    Button("Accept") {
                                        Task { await viewModel.respond(to: invitation, action: .accept) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color(red: 0.79, green: 0.58, blue: 0.99))
                                    .disabled(viewModel.isLoading)

                                    Button("Decline") {
                                        Task { await viewModel.respond(to: invitation, action: .decline) }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.white)
                                    .disabled(viewModel.isLoading)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            IOSSectionHeader("Recent decisions")

            LazyVStack(spacing: 12) {
                ForEach(viewModel.resolvedInvitations) { invitation in
                    IOSStudioCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(invitation.bandName)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(statusText(for: invitation))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.72))
                            }

                            Spacer()

                            Text(invitation.status.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(invitation.status == .accepted ? Color.green.opacity(0.26) : Color.white.opacity(0.10))
                                )
                        }
                    }
                }
            }
        }
    }

    func statusText(for invitation: IOSBandInvitation) -> String {
        switch invitation.status {
        case .pending:
            return "Awaiting your response."
        case .accepted:
            return "You joined this band."
        case .declined:
            return "You declined this invite."
        }
    }
}
