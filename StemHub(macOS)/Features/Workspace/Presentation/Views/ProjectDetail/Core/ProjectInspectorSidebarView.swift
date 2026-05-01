//
//  ProjectInspectorSidebarView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct ProjectInspectorSidebarView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    @State private var selectedBranchID: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                branchesSection
                membersSection
                commentsSection
            }
            .padding(.vertical, 2)
        }
        .studioGlassPanel(padding: 16)
        .task(id: viewModel.currentBranch?.id) {
            selectedBranchID = viewModel.currentBranch?.id ?? ""
        }
        .onChange(of: selectedBranchID) { _, newValue in
            guard
                newValue.isEmpty == false,
                newValue != viewModel.currentBranch?.id
            else {
                return
            }

            Task { await viewModel.switchBranch(newValue) }
        }
    }
}

private extension ProjectInspectorSidebarView {
    var branchesSection: some View {
        ProjectDetailPanel(title: "Branches", systemImage: "arrow.triangle.branch") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Current Branch", selection: $selectedBranchID) {
                    ForEach(viewModel.branches) { branch in
                        Text(branch.name).tag(branch.id)
                    }
                }
                .pickerStyle(.menu)
                .disabled(viewModel.branches.isEmpty || viewModel.isLoading)

                TextField("New branch name", text: $viewModel.newBranchName)
                    .textFieldStyle(.roundedBorder)

                Button("Create Branch") {
                    Task { await viewModel.createBranch() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canCreateBranch || viewModel.isLoading)
            }
        }
    }

    var membersSection: some View {
        ProjectDetailPanel(title: "Band Members", systemImage: "person.3") {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.members.isEmpty {
                    Text("No members found for this project band.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.members) { member in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name ?? member.email ?? member.id)
                                        .font(.subheadline)

                                    if let email = member.email {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if viewModel.band?.isAdmin(userID: member.id) == true {
                                    Text("Admin")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                                }
                            }
                        }
                    }
                }

                if viewModel.isCurrentUserAdmin {
                    TextField("Invite by email", text: $viewModel.inviteMemberEmail)
                        .textFieldStyle(.roundedBorder)

                    Button("Send Invite") {
                        Task { await viewModel.sendBandInvite() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canInviteMember || viewModel.isLoading)
                } else {
                    Text("Only the band admin can add new members.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !viewModel.pendingInvitations.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pending Invitations")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        ForEach(viewModel.pendingInvitations) { invitation in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(invitation.inviteeEmail)
                                        .font(.caption)
                                    Text("Waiting since \(invitation.createdAt.formatted(.dateTime.month().day().hour().minute()))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(invitation.status.title)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                            }
                        }
                    }
                }
            }
        }
    }

    var commentsSection: some View {
        ProjectDetailPanel(title: "Quick Commenting", systemImage: "text.bubble") {
            VStack(alignment: .leading, spacing: 12) {
                ProjectCommentComposerView(viewModel: viewModel)

                Divider()

                if viewModel.versionComments.isEmpty {
                    Text("No comments yet for this version.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.versionComments) { comment in
                            ProjectCommentCardView(viewModel: viewModel, comment: comment)
                        }
                    }
                }
            }
        }
    }
}
