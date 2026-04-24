//
//  MainAppShellView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI

struct MainAppShellView: View {
    @ObservedObject var authVM: AuthViewModel
    let module: WorkspaceModule
    @StateObject private var workspaceVM: WorkspaceViewModel
    @StateObject private var shellViewModel: MainAppShellViewModel
    @StateObject private var notificationsViewModel: NotificationsViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init(authVM: AuthViewModel, module: WorkspaceModule) {
        self.authVM = authVM
        self.module = module
        _workspaceVM = StateObject(wrappedValue: module.makeWorkspaceViewModel())
        _shellViewModel = StateObject(wrappedValue: module.makeShellViewModel())
        _notificationsViewModel = StateObject(wrappedValue: module.makeNotificationsViewModel())
        _profileViewModel = StateObject(wrappedValue: module.makeProfileViewModel())
        _settingsViewModel = StateObject(wrappedValue: module.makeSettingsViewModel())
    }
    
    var body: some View {
        NavigationSplitView {
            ProducerSidebarView(
                selectedSection: $shellViewModel.selectedSection,
                pendingInvitationCount: notificationsViewModel.pendingInvitationCount
            )
            .frame(minWidth: 280, idealWidth: 300, maxWidth: 320)
        } detail: {
            mainContentView
        }
        .task {
            await workspaceVM.loadWorkspaceIfNeeded()
            await notificationsViewModel.loadIfNeeded()
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        switch shellViewModel.selectedSection {
        case .workspace:
            WorkspaceView(viewModel: workspaceVM, module: module)
        case .inbox:
            NotificationsView(viewModel: notificationsViewModel)
        case .profile:
            ProfileView(viewModel: profileViewModel)
        case .settings:
            SettingsView(viewModel: settingsViewModel)
        }
    }
}
