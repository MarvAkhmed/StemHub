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

    func select(_ section: MainAppSection) {
        selectedSection = section
    }
}
