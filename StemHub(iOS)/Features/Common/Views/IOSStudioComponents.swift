//
//  IOSStudioComponents.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI
import UIKit

private enum IOSStudioPalette {
    static let backgroundTop = Color(red: 0.20, green: 0.11, blue: 0.33)
    static let backgroundBottom = Color(red: 0.08, green: 0.08, blue: 0.16)
    static let cardFill = Color.white.opacity(0.10)
    static let cardStroke = Color.white.opacity(0.10)
    static let accent = Color(red: 0.82, green: 0.59, blue: 0.99)
    static let accentSecondary = Color(red: 0.58, green: 0.41, blue: 0.93)
    static let mutedText = Color.white.opacity(0.70)
}

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

struct IOSStudioCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(IOSStudioPalette.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(IOSStudioPalette.cardStroke, lineWidth: 1)
            )
    }
}

struct IOSSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(IOSStudioPalette.mutedText)
            }
        }
    }
}

struct IOSMetricPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(IOSStudioPalette.mutedText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.10))
        )
    }
}

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

struct IOSArtworkThumbnail: View {
    let artworkBase64: String?
    let fallbackSymbol: String
    var size: CGFloat = 64

    var body: some View {
        Group {
            if
                let artworkBase64,
                let data = Data(base64Encoded: artworkBase64),
                let image = UIImage(data: data)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [IOSStudioPalette.accent, IOSStudioPalette.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: fallbackSymbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.90))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func iosStudioScreenBackground() -> some View {
        background(IOSStudioBackground())
    }
}
