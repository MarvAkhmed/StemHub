//
//  ProjectVersionHistorySidebar.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct ProjectVersionHistorySidebar: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    @State private var selectedHistory: HistorySelection = .workingCopy

    var body: some View {
        VStack(spacing: 0) {
            header
            List(selection: $selectedHistory) {
                Button(action: {
                    Task { await viewModel.loadFiles() }
                }) {
                    HStack {
                        Label("Working Copy", systemImage: "arrow.uturn.backward.circle")
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .tag(HistorySelection.workingCopy)

                ForEach(viewModel.versionHistory) { version in
                    Button(action: {
                        Task { await viewModel.loadVersionDetails(versionID: version.id) }
                    }) {
                        VersionRowView(
                            version: version,
                            isSelected: viewModel.selectedVersion?.id == version.id
                        )
                    }
                    .buttonStyle(.plain)
                    .tag(HistorySelection.version(version.id))
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .studioGlassPanel(padding: 0)
        .task(id: viewModel.selectedVersion?.id) {
            selectedHistory = currentSelection
        }
        .onChange(of: selectedHistory) { _, newValue in
            switch newValue {
            case .workingCopy:
                Task { await viewModel.loadFiles() }
            case .version(let versionID):
                Task { await viewModel.loadVersionDetails(versionID: versionID) }
            }
        }
    }
}

private extension ProjectVersionHistorySidebar {
    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Version History")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(viewModel.versionHistory.count) saved versions")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.70))
            }

            Spacer()

            if viewModel.canApproveSelectedVersion {
                Button("Approve") {
                    Task { await viewModel.approveSelectedVersion() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    var currentSelection: HistorySelection {
        if let selectedVersion = viewModel.selectedVersion {
            return .version(selectedVersion.id)
        }

        return .workingCopy
    }
}

private enum HistorySelection: Hashable {
    case workingCopy
    case version(String)
}
