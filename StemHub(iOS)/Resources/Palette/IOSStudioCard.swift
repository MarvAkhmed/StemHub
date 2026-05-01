//
//  IOSStudioCard.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 25.04.2026.
//

import SwiftUI
import UIKit

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
