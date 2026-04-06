//
//  MainAppShellView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI

struct MainAppShellView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var workspaceVM: WorkspaceViewModel
    @State private var selectedItem: String? = "Home"
    
    init(authVM: AuthViewModel, user: User) {
        self.authVM = authVM
        _workspaceVM = StateObject(wrappedValue: WorkspaceViewModel(currentUser: user))
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                Label("Home", systemImage: "house.fill").tag("Home")
                Label("Profile", systemImage: "person.fill").tag("Profile")
                Label("Settings", systemImage: "gearshape.fill").tag("Settings")
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
        } detail: {
            mainContentView()
        }
        .onChange(of: authVM.currentUser?.id) { _, _ in
            workspaceVM.currentUser = authVM.currentUser
        }
    }
    
    @ViewBuilder
    private func mainContentView() -> some View {
        switch selectedItem {
        case "Home":
            WorkspaceView(viewModel: workspaceVM)
        case "Settings":
            SettingsView(authVM: authVM)
        default:
            EmptyView()
        }
    }
}
