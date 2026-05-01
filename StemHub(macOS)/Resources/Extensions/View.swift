//
//  View.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import SwiftUI

extension View {
    // MARK: - TextFields 
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // MARK: - Liquid Glass
    func studioGlassPanel(cornerRadius: CGFloat = 22,padding: CGFloat = 18) -> some View {
        modifier(StudioGlassPanelModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func studioSafeArea(horizontal: CGFloat = 18, top: CGFloat = 14,  bottom: CGFloat = 18) -> some View {
        modifier(StudioSafeAreaModifier(horizontal: horizontal, top: top, bottom: bottom))
    }
    
    func studioToggleSwitch() -> some View {
        modifier(StudioToggleSwitchModifier())
    }
}
