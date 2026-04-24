//
//  NewProjectSheetView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 01.04.2026.
//

import SwiftUI

struct NewProjectSheetView<ViewModel: NewProjectSheetViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            StudioBackdropView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    HStack(alignment: .top, spacing: 24) {
                        leftColumn
                            .frame(width: 280)

                        rightColumn
                    }

                    footer
                }
                .padding(28)
            }
        }
        .frame(minWidth: 920, minHeight: 680)
        .interactiveDismissDisabled(viewModel.isCreating)
        .alert(
            "Create Project",
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
}

private extension NewProjectSheetView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create A New Project")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Choose the production folder, attach it to an existing band or start a new one, and set the artwork your collaborators will see in the workspace.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .studioGlassPanel(cornerRadius: 28, padding: 24)
    }

    var leftColumn: some View {
        VStack(spacing: 20) {
            posterPanel
            folderMetadataPanel
        }
    }

    var rightColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            projectBasicsPanel
            bandPanel

            if viewModel.bandMode == .newBand {
                coAdminPanel
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var posterPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelTitle("Poster Artwork", systemImage: "photo.stack")

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(StudioPalette.elevated.opacity(0.36))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [7, 8]))
                            .foregroundStyle(StudioPalette.border.opacity(0.74))
                    }

                if let image = viewModel.posterImage {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black.opacity(0.16))

                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding(12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.tv")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))

                        Text("Drop in a cover image that helps the project stand out in the workspace.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.70))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)

            HStack(spacing: 10) {
                Button("Select Poster") {
                    Task { await viewModel.selectPoster() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isCreating)

                if viewModel.posterImage != nil {
                    Button("Remove") {
                        viewModel.removePoster()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isCreating)
                }
            }
        }
        .studioGlassPanel(cornerRadius: 28, padding: 20)
    }

    var folderMetadataPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelTitle("Folder Metadata", systemImage: "folder.badge.gearshape")

            if viewModel.isLoadingFolderMetadata {
                ProgressView("Reading folder details...")
                    .tint(.white)
                    .foregroundStyle(.white.opacity(0.82))
            } else if let metadata = viewModel.folderMetadata {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(metadata.folderName)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(metadata.folderPath)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metricCard("Files", value: "\(metadata.totalFileCount)", symbol: "doc")
                        metricCard("Subfolders", value: "\(metadata.subfolderCount)", symbol: "folder")
                        metricCard("Audio", value: "\(metadata.audioFileCount)", symbol: "waveform")
                        metricCard("MIDI", value: "\(metadata.midiFileCount)", symbol: "pianokeys")
                        metricCard("Other", value: "\(metadata.nonAudioFileCount)", symbol: "tray")
                        metricCard("Size", value: metadata.totalSizeDescription, symbol: "externaldrive")
                    }

                    Label("Last updated \(metadata.lastModifiedDescription)", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.70))
                }
            } else {
                Text("Select a folder to preview the file mix, audio count, MIDI count, and size before you create the project.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .studioGlassPanel(cornerRadius: 28, padding: 20)
    }

    var projectBasicsPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            panelTitle("Project Details", systemImage: "square.and.pencil")

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Project Name")
                TextField("Midnight Session", text: $viewModel.projectName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isCreating)
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Project Folder")

                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedFolder?.lastPathComponent ?? "No folder selected")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(viewModel.selectedFolder?.path ?? "Choose the local production folder you want StemHub to track.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }

                    Spacer(minLength: 16)

                    Button(viewModel.selectedFolder == nil ? "Select Folder" : "Change Folder") {
                        Task { await viewModel.selectFolder() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isCreating)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
            }
        }
        .studioGlassPanel(cornerRadius: 28, padding: 20)
    }

    var bandPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            panelTitle("Band Assignment", systemImage: "person.3.sequence")

            Picker("Band Mode", selection: $viewModel.bandMode) {
                ForEach(NewProjectBandMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isCreating)

            switch viewModel.bandMode {
            case .newBand:
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Band Name")
                    TextField("Aurora Nights", text: $viewModel.newBandName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isCreating)

                    Text("StemHub will create a fresh band and make the listed co-admins full band admins alongside you.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                }

            case .existingBand:
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Select One Of Your Bands")

                    if viewModel.bandOptions.isEmpty {
                        Text("You are not attached to any bands yet, so this project will need a new band.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.70))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                    } else {
                        Picker("Existing Band", selection: $viewModel.selectedBand) {
                            ForEach(viewModel.bandOptions, id: \.id) { band in
                                Text(band.name).tag(band as Band?)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(viewModel.isCreating)

                        if let selectedBand = viewModel.selectedBand {
                            HStack(spacing: 12) {
                                metricCard("Members", value: "\(selectedBand.memberIDs.count)", symbol: "person.2")
                                metricCard("Admins", value: "\(selectedBand.allAdminUserIDs.count)", symbol: "person.crop.circle.badge.checkmark")
                                metricCard("Projects", value: "\(selectedBand.projectIDs.count)", symbol: "square.stack")
                            }
                        }
                    }
                }
            }
        }
        .studioGlassPanel(cornerRadius: 28, padding: 20)
    }

    var coAdminPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            panelTitle("Co-Admins", systemImage: "person.crop.circle.badge.plus")

            Text("Add existing StemHub users by email to give them band admin access from the moment this project is created.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.68))

            HStack(spacing: 12) {
                TextField("producer@stemhub.app", text: $viewModel.coAdminEmail)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isCreating)

                Button("Add") {
                    Task { await viewModel.addAdditionalAdmin() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isCreating)
            }

            if viewModel.additionalAdmins.isEmpty {
                Text("No co-admins added yet.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.additionalAdmins, id: \.id) { user in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name ?? user.email ?? user.id)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.68))
                                }
                            }

                            Spacer()

                            Button {
                                viewModel.removeAdditionalAdmin(user)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(0.70))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                }
            }
        }
        .studioGlassPanel(cornerRadius: 28, padding: 20)
    }

    var footer: some View {
        HStack(spacing: 16) {
            if viewModel.isCreating {
                ProgressView("Creating project...")
                    .tint(.white)
                    .foregroundStyle(.white.opacity(0.86))
            } else {
                Text("StemHub keeps the local folder on your Mac and links it into the collaborative workspace.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.70))
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isCreating)

            Button("Create Project") {
                createProject()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canCreate)
        }
        .studioGlassPanel(cornerRadius: 28, padding: 18)
    }

    func createProject() {
        Task {
            let success = await viewModel.createProject()
            if success {
                dismiss()
            }
        }
    }

    func panelTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.white)
    }

    func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.white.opacity(0.58))
    }

    func metricCard(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.64))

            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}
