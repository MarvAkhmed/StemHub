//
//  NewProjectSheetViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import AppKit
import Combine
import SwiftUI

@MainActor
protocol NewProjectSheetViewModelProtocol: ObservableObject {
    var posterImage: NSImage? { get set }
    var projectName: String { get set }
    var selectedFolder: URL? { get }
    var folderMetadata: CreateProjectFolderMetadata? { get }
    var bandMode: NewProjectBandMode { get set }
    var newBandName: String { get set }
    var selectedBand: Band? { get set }
    var bandOptions: [Band] { get }
    var coAdminEmail: String { get set }
    var additionalAdmins: [User] { get }
    var isLoadingFolderMetadata: Bool { get }
    var isCreating: Bool { get }
    var errorMessage: String? { get }
    var canCreate: Bool { get }

    func selectFolder() async
    func selectPoster() async
    func removePoster()
    func addAdditionalAdmin() async
    func removeAdditionalAdmin(_ user: User)
    func createProject() async -> Bool
    func clearErrorMessage()
}

@MainActor
final class NewProjectSheetViewModel: NewProjectSheetViewModelProtocol {
    @Published var posterImage: NSImage?
    @Published var projectName = ""
    @Published private(set) var selectedFolder: URL?
    @Published private(set) var folderMetadata: CreateProjectFolderMetadata?
    @Published var bandMode: NewProjectBandMode = .newBand {
        didSet {
            if bandMode == .existingBand, selectedBand == nil {
                selectedBand = bandOptions.first
            }
        }
    }
    @Published var newBandName = ""
    @Published var selectedBand: Band?
    @Published var coAdminEmail = ""
    @Published private(set) var additionalAdmins: [User] = []
    @Published private(set) var isLoadingFolderMetadata = false
    @Published private(set) var isCreating = false
    @Published private(set) var errorMessage: String?

    var bandOptions: [Band] {
        workspaceProjectCreator.bands.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var canCreate: Bool {
        let hasProjectName = !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasBandSelection: Bool

        switch bandMode {
        case .newBand:
            hasBandSelection = !newBandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .existingBand:
            hasBandSelection = selectedBand != nil
        }

        return !isCreating && selectedFolder != nil && hasProjectName && hasBandSelection
    }

    private let workspaceProjectCreator: any WorkspaceProjectCreating
    private let folderPicker: FolderPicking
    private let imagePicker: ImagePicking
    private let userLookup: any UserEmailLookup
    private let folderMetadataProvider: ProjectFolderMetadataProviding

    init(
        workspaceProjectCreator: any WorkspaceProjectCreating,
        folderPicker: FolderPicking,
        imagePicker: ImagePicking,
        userRepository: any UserEmailLookup,
        folderMetadataProvider: ProjectFolderMetadataProviding
    ) {
        self.workspaceProjectCreator = workspaceProjectCreator
        self.folderPicker = folderPicker
        self.imagePicker = imagePicker
        self.userLookup = userRepository
        self.folderMetadataProvider = folderMetadataProvider
        self.selectedBand = workspaceProjectCreator.bands.first
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    func selectFolder() async {
        guard let folder = await folderPicker.selectFolder(
            title: "Select Project Folder",
            message: "Choose the folder you want StemHub to attach and track."
        ) else {
            return
        }

        selectedFolder = folder
        if projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            projectName = folder.lastPathComponent
        }
        if newBandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newBandName = "\(folder.lastPathComponent) Band"
        }

        await loadFolderMetadata(for: folder)
    }

    func selectPoster() async {
        posterImage = await imagePicker.selectImage()
    }

    func removePoster() {
        posterImage = nil
    }

    func addAdditionalAdmin() async {
        let normalizedEmail = coAdminEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            errorMessage = "Enter an email address to add a co-admin."
            return
        }

        do {
            guard let user = try await userLookup.fetchUser(email: normalizedEmail) else {
                errorMessage = "No StemHub user was found for \(normalizedEmail)."
                return
            }

            guard !additionalAdmins.contains(where: { $0.id == user.id }) else {
                errorMessage = "\(user.email ?? normalizedEmail) is already a co-admin."
                return
            }

            additionalAdmins.append(user)
            coAdminEmail = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAdditionalAdmin(_ user: User) {
        additionalAdmins.removeAll { $0.id == user.id }
    }

    func createProject() async -> Bool {
        guard !isCreating else { return false }

        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Project name is required."
            return false
        }

        guard let folder = selectedFolder else {
            errorMessage = "Select a project folder first."
            return false
        }

        let bandSelection: CreateProjectBandSelection
        switch bandMode {
        case .newBand:
            let trimmedBandName = newBandName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedBandName.isEmpty else {
                errorMessage = "Enter a band name for the new project."
                return false
            }
            bandSelection = .new(
                name: trimmedBandName,
                additionalAdminUserIDs: additionalAdmins.map(\.id)
            )

        case .existingBand:
            guard let selectedBand else {
                errorMessage = "Select one of your existing bands."
                return false
            }
            bandSelection = .existing(selectedBand)
        }

        isCreating = true
        errorMessage = nil
        workspaceProjectCreator.clearError()

        await workspaceProjectCreator.createProject(
            CreateProjectInput(
                name: trimmedName,
                folderURL: folder,
                bandSelection: bandSelection,
                poster: posterImage
            )
        )

        isCreating = false
        if let workspaceError = workspaceProjectCreator.errorMessage {
            errorMessage = workspaceError
        }

        return errorMessage == nil
    }
}

private extension NewProjectSheetViewModel {
    func loadFolderMetadata(for folder: URL) async {
        isLoadingFolderMetadata = true
        defer { isLoadingFolderMetadata = false }

        do {
            folderMetadata = try await folderMetadataProvider.describeFolder(at: folder)
        } catch {
            folderMetadata = nil
            errorMessage = "StemHub couldn't read metadata for the selected folder."
        }
    }
}
