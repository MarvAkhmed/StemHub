//
//  AppAssembler.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

@MainActor
struct AppAssembler {
    private let dependencies: SharedAppDependencies
    let workspaceModule: WorkspaceModule
    
    init() {
        let dependencies = SharedAppDependencies()
        self.dependencies = dependencies
        self.workspaceModule = WorkspaceModule(authService: dependencies.authService)
    }

    func makeLaunchViewModels() -> LaunchViewModels {
        dependencies.makeLaunchViewModels()
    }
    
    func makeWorkspaceViewModel() -> WorkspaceViewModel {
        workspaceModule.makeWorkspaceViewModel()
    }
    
    // Updated: now takes only the project; localState is removed
    func makeProjectDetailViewModel(project: Project) -> ProjectDetailViewModel {
        workspaceModule.makeProjectDetailViewModel(project: project)
    }
}
