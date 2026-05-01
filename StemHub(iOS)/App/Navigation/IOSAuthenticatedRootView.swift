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

    @State private var workspacePath = NavigationPath()
    @State private var inboxPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    @State private var settingsPath = NavigationPath()
    
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
            // workspace
            NavigationStack(path: $workspacePath) {
                WorkspaceView(viewModel: workspaceViewModel)
            }
            .tag(IOSAppSection.workspace)
            .tabItem{Label(IOSAppSection.workspace.title, systemImage: IOSAppSection.workspace.systemImage)}
            
            // inbox
            NavigationStack(path: $inboxPath) {
                IOSInboxView(viewModel: inboxViewModel)
            }
            .tag(IOSAppSection.inbox)
            .tabItem{Label(IOSAppSection.inbox.title, systemImage: IOSAppSection.inbox.systemImage)}
            
            // Profile
            NavigationStack(path: $profilePath) {
                IOSProfileView(viewModel: profileViewModel)
            }
            .tag(IOSAppSection.profile)
            .tabItem{Label(IOSAppSection.profile.title, systemImage: IOSAppSection.profile.systemImage)}
            
            // settings
            NavigationStack(path: $settingsPath) {
                IOSSettingsView(viewModel: settingsViewModel)
            }
            .tag(IOSAppSection.settings)
            .tabItem{Label(IOSAppSection.settings.title, systemImage: IOSAppSection.settings.systemImage)}
        }
        .tint(IOSStudioPalette.accent)
        .task {  await inboxViewModel.loadIfNeeded() }
    }
}
