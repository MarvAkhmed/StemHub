//
//  StudioGlassPanelModifier.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation
import SwiftUI

struct StudioGlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 22
    var padding: CGFloat = 18
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(StudioPalette.tintSoft.opacity(0.10))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(StudioPalette.glassHighlight, lineWidth: 0.8)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(StudioPalette.border.opacity(0.78), lineWidth: 1)
                    }
                    .shadow(color: StudioPalette.shadow, radius: 12, y: 6)
            }
    }
}
