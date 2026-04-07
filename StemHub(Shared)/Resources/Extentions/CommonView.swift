//
//  View.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI

extension View {
    func platformPadding(_ edges: Edge.Set = .all, iOS: CGFloat, macOS: CGFloat) -> some View {
        modifier(PlatformPaddingModifier(edges: edges, iOSPadding: iOS, macOSPadding: macOS))
    }
    
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}
