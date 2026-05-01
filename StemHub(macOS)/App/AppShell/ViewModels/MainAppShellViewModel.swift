//
//  MainAppShellViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Combine
import Foundation

@MainActor
final class MainAppShellViewModel: ObservableObject {
    @Published var selectedSection: MainAppSection = .workspace
    @Published var pendingInvitationCount: Int = 0
    
    var pendingInvitationBadgeText: String {
        "\(pendingInvitationCount)"
    }
    
    func select(_ section: MainAppSection) {
        selectedSection = section
    }
    
    func isSelected(_ section: MainAppSection) -> Bool {
        selectedSection == section
    }
    
    func shouldShowPendingInvitationBadge(for section: MainAppSection) -> Bool {
        section == .inbox && pendingInvitationCount > 0
    }
}
