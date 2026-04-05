//
//  View.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

struct PlatformPaddingModifier: ViewModifier {
    let edges: Edge.Set
    let iOSPadding: CGFloat
    let macOSPadding: CGFloat
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content.padding(edges, iOSPadding)
        #elseif os(macOS)
        content.padding(edges, macOSPadding)
        #else
        content
        #endif
    }
}

extension View {
    func platformPadding(_ edges: Edge.Set = .all, iOS: CGFloat, macOS: CGFloat) -> some View {
        modifier(PlatformPaddingModifier(edges: edges, iOSPadding: iOS, macOSPadding: macOS))
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}

