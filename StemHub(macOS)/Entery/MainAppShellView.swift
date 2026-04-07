//
//  MainAppShellView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI

struct MainAppShellView: View {
    @ObservedObject var authVM: AuthViewModel
    let module: WorkspaceModule  // Add module as a property
    @State private var workspaceVM: WorkspaceViewModel?
    @State private var selectedItem: String? = "Home"
    
    var body: some View {
        Group {
            if authVM.isAuthenticated {
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
                            // Use module to create workspace VM
                            workspaceVM = module.makeWorkspaceViewModel()
                        }
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: authVM.isAuthenticated) { _, _ in
            if authVM.isAuthenticated {
                workspaceVM = module.makeWorkspaceViewModel()
            } else {
                workspaceVM = nil
            }
        }
    }
    
    @ViewBuilder
    private func mainContentView(workspaceVM: WorkspaceViewModel) -> some View {
        switch selectedItem {
        case "Home":
            WorkspaceView(viewModel: workspaceVM, module: module)
        case "Settings":
            SettingsView(authVM: authVM)
        default:
            EmptyView()
        }
    }
}
