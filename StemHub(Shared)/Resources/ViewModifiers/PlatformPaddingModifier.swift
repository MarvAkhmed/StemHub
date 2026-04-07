//
//  PlatformPaddingModifier.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
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

