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
    
    @State var workspacePath = NavigationPath()
    @State var inboxPath = NavigationPath()
    @State var profilePath = NavigationPath()
    @State var settingsPath = NavigationPath()
    
    @State private var selectedProject: Project?
    
    init(
        authVM: AuthViewModel,
        module: WorkspaceModule,
        workspaceVM: WorkspaceViewModel,
        shellViewModel: MainAppShellViewModel,
        notificationsViewModel: NotificationsViewModel,
        profileViewModel: ProfileViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.authVM = authVM
        self.module = module
        
        _workspaceVM = StateObject(wrappedValue: workspaceVM)
        _shellViewModel = StateObject(wrappedValue: shellViewModel)
        _notificationsViewModel = StateObject(wrappedValue: notificationsViewModel)
        _profileViewModel = StateObject(wrappedValue: profileViewModel)
        _settingsViewModel = StateObject(wrappedValue: settingsViewModel)
    }
    
    var body: some View {
        NavigationSplitView {
            MacAuthenticatedRootView(viewModel: shellViewModel)
                .frame(minWidth: 280, idealWidth: 300, maxWidth: 320)
        } detail: {
            selectedSectionView
                .id(shellViewModel.selectedSection)
        }
        .onChange(of: shellViewModel.selectedSection) { _, newSection in
                resetAllNavigationPaths()
        }
        .onChange(of: notificationsViewModel.pendingInvitationCount) { _, newValue in
            shellViewModel.pendingInvitationCount = newValue
        }
        .task {
            await workspaceVM.loadWorkspaceIfNeeded()
            await notificationsViewModel.loadIfNeeded()
            shellViewModel.pendingInvitationCount = notificationsViewModel.pendingInvitationCount
        }
    }
    
    @ViewBuilder
    private var selectedSectionView: some View {
        switch shellViewModel.selectedSection {
        case .workspace:
            NavigationStack(path: $workspacePath) {
                WorkspaceView(viewModel: workspaceVM,
                              module: module,
                              selectedProject: $selectedProject
                )
            }
            
        case .inbox:
            NavigationStack(path: $inboxPath) {
                NotificationsView(viewModel: notificationsViewModel)
            }
            
        case .profile:
            NavigationStack(path: $profilePath) {
                ProfileView(viewModel: profileViewModel)
            }
            
        case .settings:
            NavigationStack(path: $settingsPath) {
                SettingsView(viewModel: settingsViewModel)
            }
        }
    }
    
    private func resetAllNavigationPaths() {
        workspacePath = NavigationPath()
        inboxPath = NavigationPath()
        profilePath = NavigationPath()
        settingsPath = NavigationPath()
        
        selectedProject = nil
    }
}
