//
//  StudioSafeAreaModifier.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation
import SwiftUI

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
