//
//  IOSStudioBackground.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 25.04.2026.
//

import Foundation
import SwiftUI

struct IOSStudioBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                IOSStudioPalette.backgroundTop,
                Color(red: 0.12, green: 0.09, blue: 0.21),
                IOSStudioPalette.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(IOSStudioPalette.accent.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 48)
                .offset(x: 70, y: -40)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(IOSStudioPalette.accentSecondary.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 44)
                .offset(x: -50, y: 60)
        }
        .ignoresSafeArea()
    }
}
