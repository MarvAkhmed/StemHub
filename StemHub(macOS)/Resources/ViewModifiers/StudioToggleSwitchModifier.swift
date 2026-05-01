//
//  StudioToggleSwitchModifier.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 24.04.2026.
//

import SwiftUI

struct StudioToggleSwitchModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toggleStyle(.switch)
            .tint(StudioPalette.tintSoft)
    }
}
