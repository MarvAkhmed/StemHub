//
//  IOSAuthenticatedRootView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct IOSAuthenticatedRootView: View {
    @StateObject private var workspaceViewModel: WorkspaceViewModel
    @StateObject private var inboxViewModel: IOSInboxViewModel
    @StateObject private var profileViewModel: IOSProfileViewModel
    @StateObject private var settingsViewModel: IOSSettingsViewModel
    @State private var selectedSection: IOSAppSection = .workspace

    init(currentUser: User, assembler: IOSAppAssembler) {
        _workspaceViewModel = StateObject(
            wrappedValue: assembler.makeWorkspaceViewModel(currentUser: currentUser)
        )
        _inboxViewModel = StateObject(
            wrappedValue: assembler.makeInboxViewModel()
        )
        _profileViewModel = StateObject(
            wrappedValue: assembler.makeProfileViewModel()
        )
        _settingsViewModel = StateObject(
            wrappedValue: assembler.makeSettingsViewModel()
        )
    }

    var body: some View {
        TabView(selection: $selectedSection) {
            NavigationStack {
                WorkspaceView(viewModel: workspaceViewModel)
            }
            .tabItem {
                Label(IOSAppSection.workspace.title, systemImage: IOSAppSection.workspace.systemImage)
            }
            .tag(IOSAppSection.workspace)

            NavigationStack {
                IOSInboxView(viewModel: inboxViewModel)
            }
            .tabItem {
                Label(IOSAppSection.inbox.title, systemImage: IOSAppSection.inbox.systemImage)
            }
            .badge(inboxViewModel.pendingInvitationCount)
            .tag(IOSAppSection.inbox)

            NavigationStack {
                IOSProfileView(viewModel: profileViewModel)
            }
            .tabItem {
                Label(IOSAppSection.profile.title, systemImage: IOSAppSection.profile.systemImage)
            }
            .tag(IOSAppSection.profile)

            NavigationStack {
                IOSSettingsView(viewModel: settingsViewModel)
            }
            .tabItem {
                Label(IOSAppSection.settings.title, systemImage: IOSAppSection.settings.systemImage)
            }
            .tag(IOSAppSection.settings)
        }
        .tint(Color(red: 0.80, green: 0.59, blue: 0.99))
        .task {
            await inboxViewModel.loadIfNeeded()
        }
    }
}
