//
//  ProducerSidebarView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct MacAuthenticatedRootView: View {
    @ObservedObject var viewModel: MainAppShellViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProducerSidebarLayoutTokens.verticalSpacing) {
            // header
            VStack(alignment: .leading, spacing: ProducerSidebarLayoutTokens.headerSpacing) {
                Text("StemHub Studio")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("A calmer place to shape versions, feedback, and release work.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(ProducerSidebarColorTokens.secondaryTextOpacity))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, ProducerSidebarLayoutTokens.headerBottomPadding)
            
            // content
            VStack(alignment: .leading, spacing: ProducerSidebarLayoutTokens.contentSpacing) {
                ForEach(MainAppSection.allCases) { section in
                    ProducerSidebarSectionButton(
                        section: section,
                        selectedSection: $viewModel.selectedSection,
                        showsBadge: viewModel.shouldShowPendingInvitationBadge(for: section),
                        badgeText: viewModel.pendingInvitationBadgeText
                    )
                }
            }
            Spacer()
        }
        .padding(ProducerSidebarLayoutTokens.outerPadding)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            ZStack {
                Rectangle()
                    .fill(.regularMaterial)
                Rectangle()
                    .fill(
                        ProducerSidebarColorTokens.tintOverlayColor
                            .opacity(ProducerSidebarColorTokens.tintOverlayOpacity)
                    )
            }
        )
    }
}

