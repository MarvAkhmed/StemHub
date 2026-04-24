//
//  StudioGlass.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import AppKit
import SwiftUI

enum StudioPalette {
    static let canvas = Color(nsColor: NSColor.windowBackgroundColor)
    static let elevated = Color(nsColor: NSColor.controlBackgroundColor)
    static let border = Color(nsColor: NSColor.separatorColor).opacity(0.55)
    static let tint = Color(nsColor: NSColor.controlAccentColor)
    static let shadow = Color.black.opacity(0.16)
}

struct StudioBackdropView: View {
    var body: some View {
        ZStack {
            StudioPalette.canvas

            Circle()
                .fill(StudioPalette.tint.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 96)
                .offset(x: -250, y: -210)

            Circle()
                .fill(Color(nsColor: NSColor.quaternaryLabelColor).opacity(0.26))
                .frame(width: 360, height: 360)
                .blur(radius: 104)
                .offset(x: 260, y: 220)
        }
        .ignoresSafeArea()
    }
}

struct StudioGlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 22
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(StudioPalette.elevated.opacity(0.20))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(StudioPalette.border, lineWidth: 1)
                    }
                    .shadow(color: StudioPalette.shadow, radius: 16, y: 8)
            }
    }
}

struct StudioSafeAreaModifier: ViewModifier {
    var horizontal: CGFloat = 18
    var top: CGFloat = 14
    var bottom: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.horizontal, horizontal)
            .safeAreaPadding(.top, top)
            .safeAreaPadding(.bottom, bottom)
    }
}
