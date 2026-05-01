//
//  WorkspaceView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    let module: WorkspaceModule
    @Binding var selectedProject: Project?
    
    init(viewModel: WorkspaceViewModel, module: WorkspaceModule, showNewProjectSheet: Bool = false, selectedProject: Binding<Project?>, pendingDeletionItem: WorkspaceProjectItem? = nil) {
        self.viewModel = viewModel
        self.module = module
        self.showNewProjectSheet = showNewProjectSheet
        self._selectedProject = selectedProject
        self.pendingDeletionItem = pendingDeletionItem
    }
    @State private var showNewProjectSheet = false
    @State private var pendingDeletionItem: WorkspaceProjectItem?

    private let columns = [
        GridItem(.adaptive(minimum: 280), spacing: 20)
    ]

    var body: some View {
            ZStack {
                StudioBackdropView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        WorkspaceHeroPanel(
                            projectCountLabel: viewModel.projectCountLabel,
                            bandCountLabel: viewModel.bandCountLabel,
                            onCreateProject: { showNewProjectSheet = true }
                        )

                        WorkspaceSearchBar(text: $viewModel.searchText)

                        content
                    }
                    .padding(28)
                }

                if let blockingActivityMessage = viewModel.blockingActivityMessage {
                    blockingActivityOverlay(message: blockingActivityMessage)
                }
            }
            .studioSafeArea(horizontal: 0, top: 0, bottom: 0)
            .sheet(isPresented: $showNewProjectSheet) {
                NewProjectSheetView(
                    viewModel: module.makeNewProjectSheetViewModel(workspaceViewModel: viewModel)
                )
            }
            .navigationDestination(item: $selectedProject) { project in
                let detailViewModel = module.makeProjectDetailViewModel(project: project)
                ProjectDetailView(
                    viewModel: detailViewModel,
                    makeMIDIEditorViewModel: module.makeMIDIEditorViewModel
                )
            }
            .task {
                await viewModel.loadWorkspaceIfNeeded()
            }
            .alert(
                "Delete Project?",
                isPresented: Binding(
                    get: { pendingDeletionItem != nil },
                    set: { newValue in
                        if !newValue {
                            pendingDeletionItem = nil
                        }
                    }
                ),
                presenting: pendingDeletionItem
            ) { item in
                Button("Delete", role: .destructive) {
                    pendingDeletionItem = nil
                    Task { await viewModel.deleteProject(item) }
                }
                Button("Cancel", role: .cancel) {
                    pendingDeletionItem = nil
                }
            } message: { item in
                Text("“\(item.projectName)” will be removed from StemHub for collaborators in \(item.bandName). The local project folder on this Mac will stay untouched.")
            }
            .alert("Workspace", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.clearError()
                    }
                }
            )) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }
}

private extension WorkspaceView {
    @ViewBuilder
    var content: some View {
        if viewModel.isLoading && !viewModel.hasProjects {
            loadingState
        } else if !viewModel.hasProjects {
            EmptyStateView(onAddProject: { showNewProjectSheet = true })
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if viewModel.searchResultsAreEmpty {
            searchEmptyState
        } else {
            LazyVStack(alignment: .leading, spacing: 22) {
                ForEach(viewModel.visibleSections) { section in
                    WorkspaceBandSectionView(
                        section: section,
                        makeProjectCardViewModel: viewModel.makeProjectCardViewModel,
                        columns: columns,
                        onOpenProject: { selectedProject = $0 },
                        onDeleteProject: { pendingDeletionItem = $0 }
                    )
                }
            }
        }
    }

    var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)

            Text("Loading workspace…")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.86))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .studioGlassPanel(cornerRadius: 28, padding: 28)
    }

    var searchEmptyState: some View {
        ContentUnavailableView(
            "No Matching Projects",
            systemImage: "magnifyingglass",
            description: Text("Try a different project name or clear the current search.")
        )
        .foregroundStyle(.white.opacity(0.90))
        .frame(maxWidth: .infinity, minHeight: 260)
        .studioGlassPanel(cornerRadius: 28, padding: 28)
    }

    func blockingActivityOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.24)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(width: 280)
            .studioGlassPanel(cornerRadius: 28, padding: 24)
        }
        .transition(.opacity)
        .zIndex(1)
    }
}
