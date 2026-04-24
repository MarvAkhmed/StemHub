//
//  ProjectDetailMainPane.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProjectDetailMainPane: View {
    @Binding var selectedSection: ProjectDetailSection
    @ObservedObject var viewModel: ProjectDetailViewModel

    var body: some View {
        Group {
            switch selectedSection {
            case .workspace:
                ProjectWorkspaceContentView(viewModel: viewModel)
            case .comments:
                ProjectCommentsBoardView(viewModel: viewModel)
            case .changes:
                ProjectChangesBoardView(viewModel: viewModel)
            }
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.84), value: selectedSection)
    }
}
