//
//  IOSArtworkThumbnail.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 25.04.2026.
//

import Foundation
import SwiftUI

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



