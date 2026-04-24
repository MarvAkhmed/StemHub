//
//  AuthActionButton.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct AuthActionButton: View {
    enum Variant {
        case primary
        case secondary
    }

    private enum Metrics {
        static let width: CGFloat = 240

#if os(macOS)
        static let height: CGFloat = 25
#else
        static let height: CGFloat = 35
#endif
    }

    let title: String
    var variant: Variant = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.sanchezItalic24)
                .frame(
                    width: Metrics.width,
                    height: Metrics.height
                )
        }
        .background(backgroundColor)
        .cornerRadius(10)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return .buttonBackground
        case .secondary:
            return Color.gray.opacity(0.6)
        }
    }
}
