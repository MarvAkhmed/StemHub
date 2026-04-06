//
//  WorkspaceView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    @State private var showNewProjectSheet = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 220), spacing: 24)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                mainScrollView()
                
                if viewModel.isCreatingProject {
                    creationProgressOverlay()
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .sheet(isPresented: $showNewProjectSheet) {
                NewProjectSheetView(viewModel: NewProjectSheetViewModel(workspaceViewModel: viewModel))
            }
            .navigationDestination(for: Project.self) { project in
                let state = viewModel.getLocalState(for: project)
                ProjectDetailView(
                    project: project,
                    localState: state,
                    currentUserID: viewModel.currentUser?.id
                )
            }
            .task {
                await viewModel.loadProjects()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - ViewBuilders
    @ViewBuilder
    private func mainScrollView() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.projects.isEmpty {
                    EmptyStateView(onAddProject: { showNewProjectSheet = true })
                        .padding(.top, 60)
                } else {
                    titleView()
                        .padding(.horizontal)
                    projectsGridView()
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func titleView() -> some View {
        HStack {
            Text("Your Projects")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func projectsGridView() ->  some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(viewModel.projects) { project in
                NavigationLink(value: project) {
                    ProjectCard(viewModel: ProjectCardViewModel(project: project))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            newProjectCardButton()
        }
    }
    
    @ViewBuilder
    private func newProjectCardButton() -> some View {
        NewProjectCard()
            .onTapGesture { showNewProjectSheet = true }
            .cursor(NSCursor.pointingHand)
    }
    
    @ViewBuilder
    private func creationProgressOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
                Text("Creating project…")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.9))
            )
            .shadow(radius: 8)
        }
        .transition(.opacity)
        .zIndex(1)
    }
}
