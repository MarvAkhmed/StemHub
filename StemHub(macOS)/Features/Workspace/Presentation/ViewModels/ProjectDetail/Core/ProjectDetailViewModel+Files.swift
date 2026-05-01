//
//  ProjectDetailViewModel+Files.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

extension ProjectDetailViewModel {
    func selectFile(_ url: URL?) async {
        selection.selectedCommentTimestamp = nil
        applyFileSelection(
            await dependencies.fileWorkflowService.selectFile(url, projectID: project.id)
        )

        do {
            if comments.loadedCommentsVersionID == activeCommentVersionID {
                refreshSelectedFileComments()
            } else {
                try await refreshComments(forceRefresh: true)
            }
        } catch {
            ui.errorMessage = error.localizedDescription
        }
    }

    func importAudioFiles() async {
        let selectedFiles = await dependencies.audioPicker.selectAudioFiles(title: "Select Audio Files")
        guard !selectedFiles.isEmpty else { return }

        await performActivity(.importingFiles) {
            let result = try await dependencies.fileWorkflowService.importAudioFiles(
                selectedFiles,
                projectID: project.id
            )
            workspace.fileTree = result.fileTree

            if let firstImportedURL = result.importedURLs.first {
                await selectFile(firstImportedURL)
            }
        }
    }

    func selectAndUpdatePoster() async {
        guard let image = await dependencies.imagePicker.selectImage() else { return }

        await performActivity(.savingPoster) {
            let base64 = try await dependencies.projectPosterService.updatePoster(image, projectID: project.id)
            project.posterBase64 = base64
        }
    }

    func fixFolderPath() async {
        let selectedFolder = await dependencies.folderPicker.selectFolder(
            title: "Select Project Folder",
            message: "Choose the local folder for this project."
        )
        guard let selectedFolder else { return }

        await performActivity(.fixingFolder) {
            try await dependencies.fileWorkflowService.updateFolderReference(
                projectID: project.id,
                folderURL: selectedFolder
            )
            ui.showRelocationAlert = false
            try await refreshWorkspaceState(
                preserveSelectedVersionID: workspace.selectedVersion?.id,
                includeCollaborationData: false
            )
        }
    }

    func relocateProjectFolder() async {
        let destinationFolder = await dependencies.folderPicker.selectFolder(
            title: "Choose New Parent Folder",
            message: "StemHub will move this project folder there."
        )
        guard let destinationFolder else { return }

        await performActivity(.relocatingFolder) {
            try await dependencies.fileWorkflowService.relocateProjectFolder(
                projectID: project.id,
                destinationParentURL: destinationFolder
            )
            ui.showRelocationAlert = false
            try await refreshWorkspaceState(
                preserveSelectedVersionID: workspace.selectedVersion?.id,
                includeCollaborationData: false
            )
        }
    }

    func openMIDIEditor() async {
        await performActivity(.openingMIDIEditor) {
            guard let branch = resolvedBranch else {
                throw ProjectDetailError.missingBranch
            }

            let session = try await dependencies.midiSessionResolver.resolveSession(
                project: project,
                selectedFileURL: selection.selectedFileURL,
                currentBranchName: branch.name,
                currentVersionTitle: currentVersionTitle
            )

            selection.selectedFilePath = session.relativePath
            if session.fileExists {
                selection.selectedFileURL = session.fileURL
            }

            selection.midiEditorSession = session
        }
    }

    func restoreSelectedFileSelection() async {
        applyFileSelection(
            await dependencies.fileWorkflowService.restoreSelection(
                relativePath: selection.selectedFilePath,
                projectID: project.id
            )
        )
    }

    func applyFileSelection(_ selection: ProjectFileSelectionResult) {
        self.selection.selectedFileURL = selection.url
        self.selection.selectedFilePath = selection.path

        if selection.path == nil {
            comments.selectedFileComments = []
        }
    }
}
