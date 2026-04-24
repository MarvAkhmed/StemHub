//
//  NewProjectBandMode.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

enum NewProjectBandMode: String, CaseIterable, Identifiable {
    case newBand
    case existingBand

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newBand:
            return "New Band"
        case .existingBand:
            return "Existing Band"
        }
    }
}
