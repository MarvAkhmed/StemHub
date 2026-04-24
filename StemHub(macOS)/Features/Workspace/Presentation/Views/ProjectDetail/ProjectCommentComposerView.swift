//
//  ProjectCommentComposerView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProjectCommentComposerView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedFilePath = viewModel.selectedFilePath {
                Text(selectedFilePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if viewModel.selectedFileSupportsTimestamp {
                    Text("Selected time: \(viewModel.selectedCommentTimestampLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextEditor(text: $viewModel.newCommentText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 110)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                HStack {
                    Text(viewModel.selectedFileSupportsTimestamp ? "Playback comment" : "General note")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Add Comment") {
                        Task { await viewModel.addComment() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canAddComment || viewModel.isLoading)
                }
            } else {
                ContentUnavailableView(
                    "Select a File",
                    systemImage: "waveform.badge.magnifyingglass",
                    description: Text("Choose a file from the workspace before adding review notes.")
                )
            }
        }
    }
}

