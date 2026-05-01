//
//  StudioGlass.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import AppKit
import SwiftUI

enum StudioPalette {
    private static let accentNSColor = NSColor(
        srgbRed: 0.62,
        green: 0.48,
        blue: 0.92,
        alpha: 1.0
    )

    static let canvas = Color(nsColor: NSColor.windowBackgroundColor)
    static let elevated = Color(nsColor: NSColor.controlBackgroundColor)
    static let border = Color(nsColor: NSColor.separatorColor).opacity(0.55)
    static let tint = Color(nsColor: accentNSColor)
    
    static let tintSoft = Color(
        nsColor: accentNSColor.blended(withFraction: 0.60, of: .white) ?? accentNSColor
    )
    static let tintDeep = Color(
        nsColor: accentNSColor.blended(withFraction: 0.25, of: .black) ?? accentNSColor
    )
    static let glassHighlight = Color.white.opacity(0.16)
    static let shadow = Color.black.opacity(0.12)
}

struct StudioBackdropView: View {
    var body: some View {
        ZStack {
            StudioPalette.canvas

            Circle()
                .fill(StudioPalette.tint.opacity(0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .offset(x: -260, y: -210)

            Circle()
                .fill(StudioPalette.tintSoft.opacity(0.12))
                .frame(width: 400, height: 400)
                .blur(radius: 124)
                .offset(x: 250, y: 210)

            Circle()
                .fill(StudioPalette.tintDeep.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 96)
                .offset(x: 120, y: -240)
        }
        .ignoresSafeArea()
    }
}
