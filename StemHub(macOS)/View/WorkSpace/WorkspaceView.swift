//
//  WorkspaceView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    @State private var selectedProject: Project?
    @State private var showNewProjectSheet = false
    
    let columns = [
        GridItem(.adaptive(minimum: 220), spacing: 24)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("Your Projects")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { showNewProjectSheet = true }) {
                            Label("New Project", systemImage: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.projects) { project in
                            NavigationLink(value: project) {
                                ProjectCard(project: project)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .cursor(NSCursor.pointingHand)
                        }
                        NewProjectCard()
                            .onTapGesture { showNewProjectSheet = true }
                            .cursor(NSCursor.pointingHand)
                    }
                    .padding(.horizontal)
                    
                    if viewModel.projects.isEmpty {
                        EmptyStateView()
                            .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .sheet(isPresented: $showNewProjectSheet) {
                NewProjectSheetView(vm: viewModel)
            }
            .navigationDestination(for: Project.self) { project in
                let state = LocalProjectState(
                    projectID: project.id,
                    localPath: UserDefaults.standard.string(forKey: "project_\(project.id)_path") ?? "",
                    lastPulledVersionID: UserDefaults.standard.string(forKey: "project_\(project.id)_lastPulled"),
                    lastCommittedID: nil,
                    currentBranchID: project.currentBranchID
                )
                ProjectDetailView(
                    project: project,
                    localState: state,
                    currentUserID: viewModel.currentUser?.id
                )
            }
            .task { await viewModel.loadProjects() }
        }
    }
}
