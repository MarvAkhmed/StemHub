//
//  IOSUserAvatar.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 25.04.2026.
//

import Foundation
import SwiftUI

struct IOSUserAvatar: View {
    let source: String

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [IOSStudioPalette.accent, IOSStudioPalette.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(initials)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(width: 68, height: 68)
    }

    private var initials: String {
        let tokens = source.split(separator: " ").prefix(2).compactMap(\.first)
        let value = String(tokens).uppercased()
        return value.isEmpty ? "S" : value
    }
}


