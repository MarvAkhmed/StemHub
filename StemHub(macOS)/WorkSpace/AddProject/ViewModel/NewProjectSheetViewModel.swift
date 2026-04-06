//
//  NewProjectSheetViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Combine
import SwiftUI

@MainActor
protocol NewProjectSheetViewModelProtocol: ObservableObject {
    var posterImage: NSImage? { get set }
    var projectName: String { get set }
    var selectedFolder: URL? { get set }
    var selectedBand: Band? { get set }
   
    var bands: [Band] { get }
    var isCreating: Bool { get }
    var errorMessage: String? { get }
    
    func selectFolder() async
    func selectPoster() async
    func createProject() async -> Bool
    func clearErrorMessage()
}

@MainActor
final class NewProjectSheetViewModel: NewProjectSheetViewModelProtocol {
    @Published var posterImage: NSImage?
    @Published var projectName = ""
    @Published var selectedFolder: URL?
    @Published var selectedBand: Band?
    @Published private(set) var isCreating = false
    @Published private(set) var errorMessage: String?
    
    var bands: [Band] { workspaceViewModel.bands }
    
    private let workspaceViewModel: WorkspaceViewModel
    private let filePicker: FilePickerService
    
    init(workspaceViewModel: WorkspaceViewModel, filePicker: FilePickerService) {
        self.workspaceViewModel = workspaceViewModel
        self.filePicker = filePicker
    }
       
    convenience init(workspaceViewModel: WorkspaceViewModel) {
        self.init(workspaceViewModel: workspaceViewModel, filePicker: DefaultFilePickerService())
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    func selectFolder() async {
        selectedFolder = await filePicker.selectFolder()
    }
    
    func selectPoster() async {
        posterImage = await filePicker.selectImage()
    }
    
    func createProject() async -> Bool {
        guard !isCreating else { return false }
        guard !projectName.isEmpty, let folder = selectedFolder else {
            errorMessage = "Project name and folder are required."
            return false
        }
        
        isCreating = true
        errorMessage = nil
        
        await workspaceViewModel.createProject(
            name: projectName,
            folderURL: folder,
            band: selectedBand,
            poster: posterImage
        )
        
        await MainActor.run {
            isCreating = false
            if let vmError = workspaceViewModel.errorMessage {
                errorMessage = vmError
            }
        }
        return errorMessage == nil
    }
}
