//
//  NewProjectSheetView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct NewProjectSheetView: View {
    
    @ObservedObject var vm: WorkspaceViewModel
    @State private var projectName = ""
    @State private var selectedFolder: URL?
    @State private var selectedBand: Band?
    @State private var posterImage: NSImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create / Attach Project")
                .font(.title2)
            
            TextField("Project Name", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Text("Folder:")
                Button("Select Folder") {
                    selectFolder()
                }
                if let selectedFolder {
                    Text(selectedFolder.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Picker("Attach to Band", selection: $selectedBand) {
                Text("New Band").tag(Band?.none)
                ForEach(vm.bands, id: \.id) { band in
                    Text(band.name).tag(Band?.some(band))
                }
            }
            
            HStack {
                Button("Select Poster") {
                    selectPoster()
                }
                if let posterImage {
                    Image(nsImage: posterImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Create") {
                    Task {
                        await vm.createProject(
                            name: projectName,
                            folderURL: selectedFolder,
                            band: selectedBand,
                            poster: posterImage
                        )
                        dismiss()
                    }
                }
                .disabled(projectName.isEmpty || selectedFolder == nil)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            selectedFolder = panel.url
        }
    }
    
    private func selectPoster() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            if let url = panel.url {
                posterImage = NSImage(contentsOf: url)
            }
        }
    }
}
