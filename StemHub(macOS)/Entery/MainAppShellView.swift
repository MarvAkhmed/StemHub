//
//  MainAppShellView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI

struct MainAppShellView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var workspaceVM: WorkspaceViewModel?
    @State private var selectedItem: String? = "Home"
    
    var body: some View {
        Group {
            if let user = authVM.currentUser, authVM.isAuthenticated {
                if let workspaceVM = workspaceVM {
                    NavigationSplitView {
                        List(selection: $selectedItem) {
                            Label("Home", systemImage: "house.fill").tag("Home")
                            Label("Profile", systemImage: "person.fill").tag("Profile")
                            Label("Settings", systemImage: "gearshape.fill").tag("Settings")
                        }
                        .listStyle(SidebarListStyle())
                        .frame(minWidth: 200)
                    } detail: {
                        mainContentView(workspaceVM: workspaceVM)
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            workspaceVM = WorkspaceViewModel(currentUser: user)
                        }
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: authVM.currentUser?.id) { _, _ in
            if let newUser = authVM.currentUser {
                workspaceVM = WorkspaceViewModel(currentUser: newUser)
            } else {
                workspaceVM = nil
            }
        }
    }
    
    @ViewBuilder
    private func mainContentView(workspaceVM: WorkspaceViewModel) -> some View {
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
