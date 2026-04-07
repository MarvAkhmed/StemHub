//
//  NewProjectSheetView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 01.04.2026.
//

import SwiftUI

struct NewProjectSheetView<ViewModel: NewProjectSheetViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            buildHeadLabel()
            folderSelectionRow()
            bandPicker()
            posterSelectionRow()
            buildError()
            buildIsCreatingLabel()
            buildActionButtons()
        }
        .padding()
        .frame(width: 400)
        
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearErrorMessage() } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK") { }
        } message: { message in
            Text(message)
        }
    }
    
    @ViewBuilder
    private func buildHeadLabel() -> some View {
        Text("Create / Attach Project")
            .font(.title2)
        
        TextField("Project Name", text: $viewModel.projectName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disabled(viewModel.isCreating)
    }
    
    @ViewBuilder
    private func folderSelectionRow() -> some View {
        HStack {
            Text("Folder:")
            Button("Select Folder") {
                Task { await viewModel.selectFolder() }
            }
            .disabled(viewModel.isCreating)
            if let folder = viewModel.selectedFolder {
                Text(folder.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
    
    @ViewBuilder
    private func bandPicker() -> some View {
        Picker("Attach to Band", selection: $viewModel.selectedBand) {
            Text("New Band").tag(nil as Band?)
            ForEach(viewModel.bands, id: \.id) { band in
                Text(band.name).tag(band as Band?)
            }
        }
        .disabled(viewModel.isCreating)
    }
    
    @ViewBuilder
    private func buildIsCreatingLabel() -> some View {
        if viewModel.isCreating {
            ProgressView("Creating project...")
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
    
    @ViewBuilder
    private func posterSelectionRow() -> some View {
        HStack {
            Button("Select Poster") {
                Task { await viewModel.selectPoster() }
            }
            .disabled(viewModel.isCreating)
            if let image = viewModel.posterImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            }
        }
    }
    
    @ViewBuilder
    private func buildError() -> some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private func buildActionButtons() -> some View {
        HStack {
            Button("Cancel") { dismiss() }
                .disabled(viewModel.isCreating)
            Spacer()
            Button("Create") { createProject() }
            .disabled(viewModel.projectName.isEmpty || viewModel.selectedFolder == nil || viewModel.isCreating)
        }
    }
    
    private func createProject() {
        let vm = viewModel
        dismiss()
        
        Task {
            let success = await vm.createProject()
            if !success {
               print("failed to create project")
            }
        }
    }
}
